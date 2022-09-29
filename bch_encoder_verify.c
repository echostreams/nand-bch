/*-----------------------------------------------------------------------------
 * CJChen1@nuvoton, 2011/8/19, To meet Nuvoton chip design for BCH T24, we have to
 *      1. cut input data to several 1024 bytes (8192 bits) segments for T24;
 *         cut input data to several  512 bytes (4096 bits) segments for others;
 *      2. pad some bytes 0 for each data segments;
 *              for T4,  parity lenght is  60 bits <=  8 bytes, we need to padding (32-8)  bytes 0
 *              for T8,  parity lenght is 120 bits <= 15 bytes, we need to padding (32-15) bytes 0
 *              for T12, parity lenght is 180 bits <= 23 bytes, we need to padding (32-23) bytes 0
 *              for T15, parity lenght is 225 bits <= 29 bytes, we need to padding (32-29) bytes 0
 *              for T24, parity lenght is             45 bytes, we need to padding (64-45) bytes 0
 *      3. invert each data segment by bit-stream order;
 *      4. calculate BCH parity code for each data segment by normal BCH algorithm;
 *      5. invert each parity by bit-stream order.
 *
 *      Besides, we support enable/disable for SMCR[PROT_3BEN].
 *
 * CJChen1@nuvoton, 2011/1/31, To verify reliability for this program,
 *      6. modify output format in order to compare to chip data easier.
 *              output raw data (no inverting and padding) and parity with Nuvoton style.
 *---------------------------------------------------------------------------*/

#include "nuc970-bch.h"
#include <string.h>

#define CFLAG_DEBUG             0
#define CFLAG_NTC               1

#if CFLAG_NTC
#define NTC_DATA_FULL_SIZE      (ntc_data_size + data_pad_size)
#define NTC_DATA_SIZE_512       4096
#define NTC_DATA_SIZE_1024      8192
int ntc_data_size;              // the bit size for one data segment
int data_pad_size;              // the bit length to padding 0, value base on BCH type
int Redundancy_protect;         // Redundancy protect indicator

// define the total padding bytes for 512/1024 data segment
#define BCH_PADDING_LEN_512     32
#define BCH_PADDING_LEN_1024    64
// define the BCH parity code lenght for 512 bytes data pattern
#define BCH_PARITY_LEN_T4   8
#define BCH_PARITY_LEN_T8   15
#define BCH_PARITY_LEN_T12  23
#define BCH_PARITY_LEN_T15  29
// define the BCH parity code lenght for 1024 bytes data pattern
#define BCH_PARITY_LEN_T24      45
#endif

#include "bch_global.c"

int bb[rr_max];        // Parity checks

int s[rr_max];		// Syndrome values
int syn_error;		// Syndrome error indicator
int count;		// Number of errors
int location[tt_max];	// Error location
int ttx2;		// 2t
int decode_flag;	// Decoding indicator 

void parallel_syndrome() {
    /* Parallel computation of 2t syndromes.
     * Use the same lookahead matrix T_G_R of parallel computation of parity check bits.
     * The incoming streams are fed into registers from left hand
     */
    int i, j, iii, Temp, bb_temp[rr_max];
    int loop_count;

    // Determine the number of loops required for parallelism.  
    //loop_count = ceil(nn_shorten / (double)Parallel);
    // nuc970 layout
    loop_count = (int)ceil((nn_shorten + data_pad_size) / (double)Parallel);

    // Serial to parallel data conversion
    for (i = 0; i < Parallel; i++)
        for (j = 0; j < loop_count; j++)
            //if (i + j * Parallel < nn_shorten)
            if (i + j * Parallel < nn_shorten + data_pad_size)
                data_p[i][j] = recd[i + j * Parallel];
            else
                data_p[i][j] = 0;

    // Initialize the parity bits.
    for (i = 0; i < rr; i++)
        bb[i] = 0;

    // Compute syndrome polynomial: S(x) = C(x) mod g(x)
    // S(t) = T_G_R S(t-1) + R(t) 
    // Ref: L&C, pp. 225, Fig. 6.11
    for (iii = loop_count - 1; iii >= 0; iii--) {
        for (i = 0; i < rr; i++) {
            Temp = 0;
            for (j = 0; j < rr; j++)
                if (bb[j] != 0 && T_G_R[i][j] != 0)
                    Temp ^= 1;
            bb_temp[i] = Temp;
        }

        for (i = 0; i < rr; i++)
            bb[i] = bb_temp[i];

        for (i = 0; i < Parallel; i++)
            bb[i] = bb[i] ^ data_p[i][iii];
    }

    // Computation 2t syndromes based on S(x)
    // Odd syndromes
    syn_error = 0;
    for (i = 1; i <= ttx2 - 1; i = i + 2) {
        s[i] = 0;
        for (j = 0; j < rr; j++)
            if (bb[j] != 0)
                s[i] ^= alpha_to[(index_of[bb[j]] + i * j) % nn];
        if (s[i] != 0)
            syn_error = 1;	// set flag if non-zero syndrome => error
    }

    // Even syndrome = (Odd syndrome) ** 2
    for (i = 2; i <= ttx2; i = i + 2) {
        j = i / 2;
        if (s[j] == 0)
            s[i] = 0;
        else
            s[i] = alpha_to[(2 * index_of[s[j]]) % nn];
    }

    if (Verbose) {
        fprintf(stdout, "# The syndrome from parallel decoder is:\n");
        for (i = 1; i <= ttx2; i++)
            fprintf(stdout, "   %4d (%4d) == 0x%04x (0x%x)\n", s[i], index_of[s[i]], s[i], index_of[s[i]]);
        fprintf(stdout, "\n\n");
    }
}

void decode_bch() {
    register int i, j, elp_sum;
    Verbose = 1;
    ttx2 = 2 * tt;

#ifdef _MSC_VER
    int* L = malloc((ttx2 + 3) * sizeof(int));
    int* u_L = malloc((ttx2 + 3) * sizeof(int));
    int* reg = malloc((ttx2 + 3) * sizeof(int));
    int** elp = malloc((ttx2 + 4) * sizeof(int*));
    for (i = 0; i < ttx2 + 4; i++)
        elp[i] = malloc((ttx2 + 4) * sizeof(int));
    int* desc = malloc((ttx2 + 4) * sizeof(int));
#else
    int L[ttx2 + 3];			// Degree of ELP 
    int u_L[ttx2 + 3];		    // Difference between step number and the degree of ELP
    int reg[tt + 3];			// Register state
    int elp[ttx2 + 4][ttx2 + 4]; 	// Error locator polynomial (ELP)
    int desc[ttx2 + 4];		    // Discrepancy 'mu'th discrepancy
#endif
    int u;				// u = 'mu' + 1 and u ranges from -1 to 2*t (see L&C)
    int q;				//

    parallel_syndrome();

    if (!syn_error) {
        decode_flag = 1;	// No errors
        count = 0;
    }
    else {
        // Having errors, begin decoding procedure
        // Simplified Berlekamp-Massey Algorithm for Binary BCH codes
        // 	Ref: Blahut, pp.191, Chapter 7.6 
        // 	Ref: L&C, pp.212, Chapter 6.4
        //
        // Following the terminology of Lin and Costello's book:   
        // 	desc[u] is the 'mu'th discrepancy, where  
        // 	u='mu'+1 and 
        // 	'mu' (the Greek letter!) is the step number ranging 
        // 		from -1 to 2*t (see L&C)
        // 	l[u] is the degree of the elp at that step, and 
        // 	u_L[u] is the difference between the step number 
        // 		and the degree of the elp. 

        if (Verbose) fprintf(stdout, "Beginning Berlekamp loop\n");

        // initialise table entries
        for (i = 1; i <= ttx2; i++)
            s[i] = index_of[s[i]];

        desc[0] = 0;				/* index form */
        desc[1] = s[1];				/* index form */
        elp[0][0] = 1;				/* polynomial form */
        elp[1][0] = 1;				/* polynomial form */
        //elp[2][0] = 1;				/* polynomial form */
        for (i = 1; i < ttx2; i++) {
            elp[0][i] = 0;			/* polynomial form */
            elp[1][i] = 0;			/* polynomial form */
            //elp[2][i] = 0;			/* polynomial form */
        }
        L[0] = 0;
        L[1] = 0;
        //L[2] = 0;
        u_L[0] = -1;
        u_L[1] = 0;
        //u_L[2] = 0;
        u = -1;

        do {
            // even loops always produce no discrepany so they can be skipped
            u = u + 2;
            if (Verbose) fprintf(stdout, "Loop %d:\n", u);
            if (Verbose) fprintf(stdout, "     desc[%d] = %x\n", u, desc[u]);
            if (desc[u] == -1) {
                L[u + 2] = L[u];
                for (i = 0; i <= L[u]; i++)
                    elp[u + 2][i] = elp[u][i];
            }
            else {
                // search for words with greatest u_L[q] for which desc[q]!=0 
                q = u - 2;
                if (q < 0) q = 0;
                // Look for first non-zero desc[q] 
                while ((desc[q] == -1) && (q > 0))
                    q = q - 2;
                if (q < 0) q = 0;

                // Find q such that desc[u]!=0 and u_L[q] is maximum
                if (q > 0) {
                    j = q;
                    do {
                        j = j - 2;
                        if (j < 0) j = 0;
                        if ((desc[j] != -1) && (u_L[q] < u_L[j]))
                            q = j;
                    } while (j > 0);
                }

                // store degree of new elp polynomial
                if (L[u] > L[q] + u - q)
                    L[u + 2] = L[u];
                else
                    L[u + 2] = L[q] + u - q;

                // Form new elp(x)
                for (i = 0; i < ttx2; i++)
                    elp[u + 2][i] = 0;
                for (i = 0; i <= L[q]; i++)
                    if (elp[q][i] != 0)
                        elp[u + 2][i + u - q] = alpha_to[(desc[u] + nn - desc[q] + index_of[elp[q][i]]) % nn];
                for (i = 0; i <= L[u]; i++)
                    elp[u + 2][i] ^= elp[u][i];

            }
            u_L[u + 2] = u + 1 - L[u + 2];

            // Form (u+2)th discrepancy.  No discrepancy computed on last iteration 
            if (u < ttx2) {
                if (s[u + 2] != -1)
                    desc[u + 2] = alpha_to[s[u + 2]];
                else
                    desc[u + 2] = 0;

                for (i = 1; i <= L[u + 2]; i++)
                    if ((s[u + 2 - i] != -1) && (elp[u + 2][i] != 0))
                        desc[u + 2] ^= alpha_to[(s[u + 2 - i] + index_of[elp[u + 2][i]]) % nn];
                // put desc[u+2] into index form 
                desc[u + 2] = index_of[desc[u + 2]];

            }

            if (Verbose) {
                fprintf(stdout, "     deg(elp) = %2d --> elp(%2d):", L[u], u);
                for (i = 0; i <= L[u]; i++)
                    fprintf(stdout, "  0x%x", elp[u][i]);
                fprintf(stdout, "\n");
                fprintf(stdout, "     deg(elp) = %2d --> elp(%2d):", L[u + 2], u + 2);
                for (i = 0; i <= L[u + 2]; i++)
                    fprintf(stdout, "  0x%x", elp[u + 2][i]);
                fprintf(stdout, "\n");
                fprintf(stdout, "     u_L[%2d] = %2d\n", u, u_L[u]);
                fprintf(stdout, "     u_L[%2d] = %2d\n", u + 2, u_L[u + 2]);
            }

        } while ((u < (ttx2 - 1)) && (L[u + 2] <= tt));
        if (Verbose) fprintf(stdout, "\n");
        u = u + 2;
        L[ttx2 - 1] = L[u];

        if (L[ttx2 - 1] > tt)
            decode_flag = 0;
        else {
            // Chien's search to find roots of the error location polynomial
            // Ref: L&C pp.216, Fig.6.1
            if (Verbose) fprintf(stdout, "Chien Search:  L[%d]=%d=%x\n", ttx2 - 1, L[ttx2 - 1], L[ttx2 - 1]);
            if (Verbose) fprintf(stdout, "Sigma(x) = \n");

            if (Verbose)
                for (i = 0; i <= L[u]; i++)
                    if (elp[u][i] != 0)
                        fprintf(stdout, "    %4d (%4d)\n", elp[u][i], index_of[elp[u][i]]);
                    else
                        fprintf(stdout, "     0\n");

            for (i = 1; i <= L[ttx2 - 1]; i++) {
                reg[i] = index_of[elp[u][i]];
                if (Verbose) fprintf(stdout, "  reg[%d]=%d=%x\n", i, reg[i], reg[i]);
            }
            count = 0;
            // Begin chien search 
            for (i = 1; i <= nn; i++) {
                elp_sum = 1;
                for (j = 1; j <= L[ttx2 - 1]; j++)
                    if (reg[j] != -1) {
                        reg[j] = (reg[j] + j) % nn;
                        elp_sum ^= alpha_to[reg[j]];
                    }

                // store root and error location number indices
                if (!elp_sum) {
                    location[count] = nn - i;
                    if (Verbose) fprintf(stdout, "count: %d location: %d L[ttx2-1] %d\n",
                        count, location[count], L[ttx2 - 1]);
                    count++;
                }
            }

            // Number of roots = degree of elp hence <= tt errors
            if (count == L[ttx2 - 1]) {
                decode_flag = 1;
                // Correct errors by flipping the error bit
                for (i = 0; i < L[ttx2 - 1]; i++)
                    recd[location[i]] ^= 1;
            }
            // Number of roots != degree of ELP => >tt errors and cannot solve
            else
                decode_flag = 0;
        }
    }

#ifdef _MSC_VER
    free(L);
    free(u_L);
    free(reg);
    for (i = 0; i < ttx2 + 4; i++)
        free(elp[i]);
    free(elp);
    free(desc);
#endif

    printf("  decode_flag: %d\n", decode_flag);
}

void parallel_encode_bch(unsigned char* input_ra_data)
/* Parallel computation of n - k parity check bits.
 * Use lookahead matrix T_G_R.
 * The incoming streams are fed into registers from the right hand
 */
{
    int i, j, iii, Temp, bb_temp[rr_max];
    int loop_count;

#if CFLAG_NTC
    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2011/1/20, To meet Nuvoton chip design, we have to
     *      2. pad some bytes 0 for each data segments;
     *      3. invert each data segment by bit-stream order;
     *      The length of data segment MUST be (segment+padding) bits.
     *      Element of data[x] is one bit for input data.
     *
     *      Besides, we support enable/disable for SMCR[PROT_3BEN].
     *      Here, we modify padding data according to variable Redundancy_protect.
     *---------------------------------------------------------------------------*/
    for (i = kk_shorten; i < NTC_DATA_FULL_SIZE; i++) // padding 0
    {
        data[i] = 0;
    }

    // to support SMCR[PROT_3BEN] enable function.
    if (Redundancy_protect)
    {
        //        for (i = kk_shorten; i < kk_shorten + 16; i++)
        //            data[i] = 1;    // padding redundancy data 0xffff00 if SMCR[PROT_3BEN] enable

                // padding redundancy data from input_ra_data if SMCR[PROT_3BEN] enable
        for (i = 0; i < 24; i++)
        {
            j = i / 8;      // byte index of input_ra_data[]
            if (i % 8 == 0)
                iii = 7;    // bit index of input_ra_data[j]
            data[kk_shorten + i] = (input_ra_data[j] >> iii) & 0x01;  // convert one bit one element of data[]
            iii--;
        }
    }

    kk_shorten += data_pad_size;  // temporarily, extend kk_shorten to include padding 0

    //
    print_hex_low(kk_shorten, data, stdout);
    printf("\n\n");

    i = 0;
    j = NTC_DATA_FULL_SIZE - 1;   // always invert (raw data + padding data)
    while (i < j)
    {
        Temp = data[i];
        data[i] = data[j];
        data[j] = Temp;
        i++;
        j--;
    }
#endif

    // Determine the number of loops required for parallelism.
    loop_count = (int)ceil(kk_shorten / (double)Parallel);

    // Serial to parallel data conversion
    for (i = 0; i < Parallel; i++)
    {
        for (j = 0; j < loop_count; j++)
        {
            Temp = i + j * Parallel;
            if (Temp < kk_shorten)
                data_p[i][j] = data[Temp];
            else
                data_p[i][j] = 0;
        }
    }

    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2011/1/20, modify nothing, just describe the structure of data_p.
     *      Element of data_p[r][c] is one bit for input stream. The bit order is
     *          data_p[0][0]=bit 0,     data_p[0][1]=bit p,    ...    , data_p[0][loop_count-1]
     *          data_p[1][0]=bit 1,     data_p[1][1]=bit p+1,  ...    , data_p[1][loop_count-1]
     *               ...                     ...
     *          data_p[p-1][0]=bit p-1, data_p[p-1][1]=bit 2*p-1, ... , data_p[p-1][loop_count-1]
     *          where p is Parallel.
     *---------------------------------------------------------------------------*/

     // Initialize the parity bits.
    for (i = 0; i < rr; i++)
        bb[i] = 0;

    // Compute parity checks
    // S(t) = T_G_R [ S(t-1) + M(t) ]
    // Ref: Parallel CRC, Shieh, 2001
    for (iii = loop_count - 1; iii >= 0; iii--)
    {
        for (i = 0; i < rr; i++)
            bb_temp[i] = bb[i];
        for (i = Parallel - 1; i >= 0; i--)
            bb_temp[rr - Parallel + i] = bb_temp[rr - Parallel + i] ^ data_p[i][iii];

        for (i = 0; i < rr; i++)
        {
            Temp = 0;
            for (j = 0; j < rr; j++)
                Temp = Temp ^ (bb_temp[j] & T_G_R[i][j]);
            bb[i] = Temp;
        }
    }

#if CFLAG_NTC
    kk_shorten -= data_pad_size;  // recover kk_shorten

/*-----------------------------------------------------------------------------
 * CJChen1@nuvoton, 2011/1/20, To meet Nuvoton chip design, we have to
 *      5. invert each parity by bit-stream order.
 *      Element of bb[x] is one bit for output parity.
 *---------------------------------------------------------------------------*/
    i = 0;
    j = rr - 1;
    while (i < j)
    {
        Temp = bb[i];
        bb[i] = bb[j];
        bb[j] = Temp;
        i++;
        j--;
    }
#endif
}


int calculate_BCH_parity_in_field(
    unsigned char* input_data,
    unsigned char* input_ra_data,
    int bch_error_bits,
    int protect_3B,
    int field_index,
    unsigned char* output_bch_parity,
    int bch_need_initial)
{
    //int field_parity_size;      // the BCH parity size for one field to return
    int input_data_index;
    int i, j;
    int in_count, in_v, in_codeword;    // Input statistics
    char in_char;

    fprintf(stderr, "\n# Binary BCH encoder. field index: %d.\n", field_index);
    input_data_index = 0;

#if CFLAG_NTC
    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2011/1/27, To meet Nuvoton chip design, we have to
     *      support enable/disable for SMCR[PROT_3BEN].
     *      Here, we disable this feature by default.
     *---------------------------------------------------------------------------*/
    Redundancy_protect = 0;
#endif

    Verbose = 0;
    mm = df_m;
    tt = df_t;
    Parallel = df_p;

    //--- initial BCH parameters for Nuvoton
    mm = 15;
    tt = bch_error_bits;
    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2011/1/28, To meet Nuvoton chip design, we have to
     *      2. pad some bytes 0 for each data segments;
     *      Here, we set the data size and padding size according to bch_error_bits
     *---------------------------------------------------------------------------*/
    switch (tt)
    {
    case  4: ntc_data_size = NTC_DATA_SIZE_512;
        data_pad_size = (BCH_PADDING_LEN_512 - BCH_PARITY_LEN_T4) * 8;   break;  // *8 : byte --> bit
    case  8: ntc_data_size = NTC_DATA_SIZE_512;
        data_pad_size = (BCH_PADDING_LEN_512 - BCH_PARITY_LEN_T8) * 8;   break;
    case 12: ntc_data_size = NTC_DATA_SIZE_512;
        data_pad_size = (BCH_PADDING_LEN_512 - BCH_PARITY_LEN_T12) * 8;  break;
    case 15: ntc_data_size = NTC_DATA_SIZE_512;
        data_pad_size = (BCH_PADDING_LEN_512 - BCH_PARITY_LEN_T15) * 8;  break;
    case 24: ntc_data_size = NTC_DATA_SIZE_1024;
        data_pad_size = (BCH_PADDING_LEN_1024 - BCH_PARITY_LEN_T24) * 8; break;
    default:
        fprintf(stderr, "### t must be 4 or 8 or 12 or 15 or 24.\n\n");
        break;
    }

    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2012/7/27, according to Parallel CRC request,
     *      the Parallel MUST < parity code length (n-k), so, for Nuvoton
     *          for T4,  parity lenght is  60 bits, max Parallel is 32
     *          for T8,  parity lenght is 120 bits, max Parallel is 64
     *          for T12, parity lenght is 180 bits, max Parallel should be 128
     *          for T15, parity lenght is 225 bits, max Parallel should be 128
     *          for T24, parity lenght is 360 bits, ??
     *      Please also modify the parallel_max definition in bch_global.c
     *---------------------------------------------------------------------------*/
    if (bch_error_bits == 4)
        Parallel = 32 /*8*/;
    else
        Parallel = 64 /*8*/;
    Redundancy_protect = protect_3B;

#if CFLAG_NTC
    /*-----------------------------------------------------------------------------
     * CJChen1@nuvoton, 2011/1/20, To meet Nuvoton chip design, we have to
     *      1. cut input data to several 512/1024 bytes segments;
     *      Here, we force kk_shorten=4096/8192 bits so that algorithm will
     *      calculate one BCH parity code for each 512/1024 bytes segment.
     *---------------------------------------------------------------------------*/
    kk_shorten = ntc_data_size;

    // to show configuration about SMCR[PROT_3BEN] function.
/*
    if (Redundancy_protect)
        fprintf(stdout, "{### Enable SMCR[PROT_3BEN] feature.}\n");
    else
        fprintf(stdout, "{### Disable SMCR[PROT_3BEN] feature.}\n");
*/
#endif

    if (bch_need_initial)
    {
        //--- really do BCH encoding
        nn = (int)pow(2, mm) - 1;
        nn_shorten = nn;

        // generate the Galois Field GF(2**mm)
        generate_gf();

        // Compute the generator polynomial and lookahead matrix for BCH code
        gen_poly();

        // Check if code is shortened
        nn_shorten = kk_shorten + rr;
    }   // end of if(bch_need_initial)

        fprintf(stdout, "{# (m = %d, n = %d, k = %d, t = %d) Binary BCH code.}\n", mm, nn_shorten, kk_shorten, tt) ;

        // Read in data stream
    in_count = 0;
    in_codeword = 0;

    in_char = input_data[input_data_index++];
    while (input_data_index <= (ntc_data_size / 8))
    {
        in_v = (int)in_char;
        for (i = 7; i >= 0; i--)
        {
            if ((int)pow(2, i) & in_v)
                data[in_count] = 1;
            else
                data[in_count] = 0;

            in_count++;
        }

        /*-----------------------------------------------------------------------------
        * CJChen1@nuvoton, 2011/1/20, To meet Nuvoton chip design, we have to
        *      1. cut input data to several 512/1024 bytes segments;
        *      Here, original program cut input data to 512 bytes if kk_shorten=4096 (512 bytes)
        *---------------------------------------------------------------------------*/
        if (in_count == kk_shorten)
        {
            in_codeword++;

#if CFLAG_NTC // CJChen1, for debugging, show data before pad and invert
            /*-----------------------------------------------------------------------------
            * CJChen1@nuvoton, 2011/1/31, To verify reliability for this program,
            *      6. modify output format in order to compare to chip data easier.
            *              output raw data (no inverting and padding) and parity with Nuvoton style.
            *---------------------------------------------------------------------------*/
            //fprintf(stdout, "show raw data before pad and invert:\n");
            //print_hex_low(kk_shorten, data, stdout);
            //fprintf(stdout, "\n");
#endif
            parallel_encode_bch(input_ra_data);

#if CFLAG_NTC   // CJChen1@nuvoton, 2011/1/20, to show data that include padding data
            /*-----------------------------------------------------------------------------
            * CJChen1@nuvoton, 2011/1/31, To verify reliability for this program,
            *      6. modify output format in order to compare to chip data easier.
            *              output raw data (no inverting and padding) and parity with Nuvoton style.
            *---------------------------------------------------------------------------*/
            //print_hex_low(NTC_DATA_FULL_SIZE, data, stdout);
            //fprintf(stdout, "\n");
#else
            print_hex_low(kk_shorten, data, stdout);
#endif
            fprintf(stdout, "    ");
            print_hex_low(rr, bb, stdout);
            fprintf(stdout, "\n") ;
        }

        in_char = input_data[input_data_index++];
    }   // end of while()
    //fprintf(stdout, "\n{### %d words encoded.}\n", in_codeword) ;

    // copy parity code from bb (bit array) to output_bch_parity (byte array)
    output_bch_parity[0] = 0;
    for (i = 0, j = 0; i < rr; i++)
    {
        output_bch_parity[j] = (output_bch_parity[j] << 1) + bb[i];
        if (i % 8 == 7)
        {
            output_bch_parity[++j] = 0;     // initial next byte
        }
    }

    if (rr % 8 == 0)
        return(rr / 8);   // return parity code lenght with unit byte
    else
    {
        // if rr cannot dividable by 8, padding bit 0 after it.
        output_bch_parity[j] = (output_bch_parity[j] << (8 - (rr % 8)));
        return((rr / 8) + 1);
    }
}

int nuc970_convert_data(NUC970FmiState* fmi, unsigned char* page, int field_index, int oob_size, int error_bits)
{
    int field_size;
    //int in_count, in_v, in_codeword;    // Input statistics
    int i, j, iii;
    int eccbytes;
    unsigned char* input_ra_data = &page[2048];
    for (i = 0; i < oob_size; i++) {
        fmi->FMI_NANDRA[i] = ((uint32_t*)input_ra_data)[i];
    }
    switch (error_bits)
    {
    case  4:
        field_size = 512;
        break;
    case  8:
        field_size = 512;
        break;
    case 12:
        field_size = 512;
        break;
    case 15:
        field_size = 512;
        break;
    case 24:
        field_size = 1024;
        break;
    default:
        printf("ERROR: BCH T must be 4 or 8 or 12 or 15 or 24.\n\n");
        return 1;
    }

    // recd[0 ~ rr] = parity bits
    // recd[rr ~ (rr + NTC_DATA_FULL_SIZE)] = data bits

    for (i = 0; i < field_size; i++) {
        for (j = 0; j < 8; j++) {
            recd[rr + i * 8 + j] = page[field_index * field_size + i] >> (7 - j) & 0x01;
        }
    }

    for (i = rr + kk_shorten; i < rr + NTC_DATA_FULL_SIZE; i++) // padding 0
    {
        recd[i] = 0;
    }

    // to support SMCR[PROT_3BEN] enable function.
    if (field_index == 0)
    {
        //        for (i = kk_shorten; i < kk_shorten + 16; i++)
        //            data[i] = 1;    // padding redundancy data 0xffff00 if SMCR[PROT_3BEN] enable
        // padding redundancy data from input_ra_data if SMCR[PROT_3BEN] enable
        for (i = 0; i < 24; i++)
        {
            j = i / 8;      // byte index of input_ra_data[]
            if (i % 8 == 0)
                iii = 7;    // bit index of input_ra_data[j]
            recd[rr + kk_shorten + i] = (input_ra_data[j] >> iii) & 0x01;  // convert one bit one element of data[]
            iii--;
        }
    }

    //
    //print_hex_low(NTC_DATA_FULL_SIZE, recd, stdout);
    //printf("\n\n");

    i = 0;
    j = NTC_DATA_FULL_SIZE - 1;   // always invert (raw data + padding data)
    while (i < j)
    {
        int Temp = recd[rr + i];
        recd[rr + i] = recd[rr + j];
        recd[rr + j] = Temp;
        i++;
        j--;
    }

    if (rr % 8 == 0)
        eccbytes = (rr / 8);   // return parity code lenght with unit byte
    else
    {
        eccbytes = ((rr / 8) + 1);
    }

    for (i = 0; i < eccbytes; i++)
    {
        printf(" %02x", page[2048 + 32 + (field_index * eccbytes) + i]);
        for (j = 0; j < 8; j++) {            
            recd[0 + (i * 8) + j] = 
                page[2048 + 32 + (field_index * eccbytes) + i] >> (7 - j) & 0x01;
        }
    }
    printf("\n");    

    // invert parity code
    i = 0;
    j = rr - 1;
    while (i < j)
    {
        int Temp = recd[0 + i];
        recd[0 + i] = recd[0 + j];
        recd[0 + j] = Temp;
        i++;
        j--;
    }

    //
    print_hex_low(NTC_DATA_FULL_SIZE + eccbytes * 8, recd, stdout);
    printf("\n\n");

    return 0;
}

int recd_data[kk_max], recd_parity[kk_max];
int code_success[kk_max], code_fail[kk_max];	// Decoded and failed words
void post_decode(NUC970FmiState *fmi, int field_index)
{
    int Output_Syndrome = 1;
    int in_codeword = 1;
    int i;
    int decode_success, decode_fail;		// Decoding statistics
    
    decode_success = 0;
    decode_fail = 0;
    
    if (decode_flag == 1) {
        decode_success++;
        code_success[decode_success] = in_codeword;
        if (count == 0)
            fprintf(stdout, "{ Codeword %d: No errors.}\n", in_codeword);
        else {
            
            fmi->FMI_NANDINTSTS |= (1 << 2); // ECC_FLD_IF (ECC Field Check Error Interrupt Flag)
            
            int* byte_err_locations = malloc(sizeof(int) * df_t);
            unsigned char* byte_err_datas = malloc(df_t);
            memset(byte_err_locations, 0xff, sizeof(int) * df_t);
            memset(byte_err_datas, 0, df_t);
            int byte_err_count = 0;
  
            fprintf(stdout, "{ Codeword %d: %d errors found at location:", in_codeword, count);
            /* location layout
             * [rr:60][data_pad_size:192][kk_shorten:4096]
             */
            for (i = 0; i < count; i++) {
                int loc;
                // Convert error location from systematic form to storage form 
                if (location[i] >= rr) {
                    loc = rr + data_pad_size + kk_shorten - 1 - location[i];
                }
                else {
                    int eccbytes = (rr % 8 == 0) ? (rr / 8) : ((rr / 8) + 1);

                    loc = rr - 1 - location[i]      // reversed bits
                        + kk_shorten + data_pad_size;
                }
                fprintf(stdout, " %d", loc);
                if (!byte_err_count || byte_err_locations[byte_err_count - 1] != loc / 8)
                {
                    byte_err_datas[byte_err_count] |= 1 << (7 - (loc % 8));
                    byte_err_locations[byte_err_count++] = loc / 8;                    
                }
                else {
                    byte_err_datas[byte_err_count - 1] |= 1 << (7 - (loc % 8));
                }
            }
            fprintf(stdout, "}\n");
            fprintf(stdout, "{ Byte location: ");
            for (i = 0; i < byte_err_count; i++) {
                fprintf(stdout, " %d(%02x)", byte_err_locations[i], byte_err_datas[i]);
                fmi->FMI_NANDECCEA[field_index][i / 2] |= (byte_err_locations[i] & 0x7ff) << (16 * (i % 2));
                fmi->FMI_NANDECCED[field_index][i / 4] |= (byte_err_datas[i]) << (8 * (i % 4));
            }
            fprintf(stdout, "}\n");
            free(byte_err_locations);
            free(byte_err_datas);
            fmi->FMI_NANDECCES[field_index / 4] |= ((byte_err_count << 2) | 0x01) << (field_index % 4);
            
            printf("\n");
        }
    }
    else {
        decode_fail++;
        code_fail[decode_fail] = in_codeword;
        fprintf(stdout, "{ Codeword %d: Unable to decode!}", in_codeword);
        printf("\n");
    }

    // Convert decoded data into information data and parity checks
    for (i = 0; i < kk_shorten; i++)
        recd_data[i] = recd[i + rr];
    for (i = 0; i < rr; i++)
        recd_parity[i] = recd[i];
    print_hex_low(kk_shorten, recd_data, stdout);
    printf("\n");
    if (Output_Syndrome == 1) {
        fprintf(stdout, "    ");
        print_hex_low(rr, recd_parity, stdout);
        printf("\n");
        if (Verbose) fprintf(stdout, "rr: %d\n", rr);
    }
    fprintf(stdout, "\n\n");

    fprintf(stdout, "{### %d codewords received.}\n", in_codeword);
    fprintf(stdout, "{@@@ %d codewords are decoded successfully:}\n{", decode_success);
    for (i = 1; i <= decode_success; i++)
        fprintf(stdout, " %d", code_success[i]);
    fprintf(stdout, " }\n");
    fprintf(stdout, "{!!! %d codewords are unable to correct:}\n{", decode_fail);
    for (i = 1; i <= decode_fail; i++)
        fprintf(stdout, " %d", code_fail[i]);
    fprintf(stdout, " }\n");
}
