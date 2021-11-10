#include <stdint.h>
#include <stdio.h>
#include <scone_rt_ext.h>
#include <string.h>
#include "httpclient.h"
#include "./jsmn.h"
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>

//
// Turn on/off DEBUG prints
//
#define DEBUG 0

//
// JSON comparison routine
//
static int jsoneq(const char *json, jsmntok_t *tok, const char *s) {
  if (tok->type == JSMN_STRING && (int)strlen(s) == tok->end - tok->start &&
      strncmp(json + tok->start, s, tok->end - tok->start) == 0) {
    return 0;
  }
  return -1;
}

//
// Get the process Measurement from SensLAS
//
bool getProcessMeasurement (int pid, uint8_t *measurement)
{
    int i;
    int r;
    char resp[4096];
    char *args[7];
    char pidStr[16];

    // Get Hostname and Port from environment
    char *h = getenv("SENSORIANT_ATTESTATION_HOST");
    if (!h) {
	h = "senslas";
    }
    char *p = getenv("SENSLAS_PORT");
    if (!p) {
        p = "9004";
    }
#if DEBUG
    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Entering getProcessMeasurement..\n");
#endif
    memset(pidStr, 0, sizeof(pidStr));
    sprintf(pidStr, "%d", pid);

    args[1] = h;
    args[2] = p;
    args[3] = "POST";
    args[4] = "/GetMeasurement";

    args[5] = "measurementType=PROCESS&processId=";
    char postparam[4096];
    memset(postparam, 0, sizeof(postparam));
    strcpy(postparam, args[5]);
    strcat(postparam, pidStr);
    args[5]=postparam;
    char urlparams[4096];
    memset(urlparams, 0, sizeof(urlparams));
    strcpy(urlparams, args[4]);
    strcat(urlparams,"?");
    strcat(urlparams,args[5]);
    args[4] = urlparams;
    args[6] = "Content-Type: application/x-www-form-urlencoded";

    // Send to Server
    memset(resp,0,sizeof(resp));
    httpclient(6,args,resp);
#if DEBUG
    printf("urlparams = %s\n", urlparams);
    printf("\nLUKE resp=\n%s",resp);
#endif
    
    // Parse response
    char *jsonStart = strstr(resp, "{");
    if ( !jsonStart )
    {
        printf("Invalid Response");
    }
    else
    {
        char *ret;
        ret = strstr(resp, "{");
        jsmn_parser p;
        jsmntok_t t[128]; /* We expect no more than 128 tokens */

        jsmn_init(&p);
        r = jsmn_parse(&p, ret, strlen(ret), t, sizeof(t) / sizeof(t[0]));
        if (r < 0) {
            printf("Failed to parse JSON: %d\n", r);
            return 1;
        }
        
        // Get Measurement as string
        char measurementStr[64+1];
        memset(measurementStr,0,sizeof(measurementStr));
        for (i = 1; i < r; i++) {
            if (jsoneq(ret, &t[i], "measurement") == 0) {
                sprintf(measurementStr, "%.*s", t[i + 1].end - t[i + 1].start, ret + t[i + 1].start);
                    i++;
            }
        }
#if DEBUG
        printf ("\n\nLUKE: measurementStr = %s\n\n", measurementStr);
#endif
        // Convert to byte array
         /* WARNING: no sanitization or error-checking whatsoever */
        char *pos = measurementStr;
        for (size_t count = 0; count < 32; count++) {
            sscanf(pos, "%2hhx", &measurement[count]);
            pos += 2;
        }
    }
}

//
// Sign Report with EDDSA Public Key in SensLAS
//
bool signReportEDDSA(uint8_t *reportData, uint16_t reportDataSize, uint8_t *signature)
{
    int i;
    int r;
    //char pubkey[64];
    char resp[4096];
    char *args[7];
    char rd[64];

#if DEBUG
    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Entering signReportEDDSA..\n");
    //printf("reportData = %s\n", reportData);
    //printf("reportDataSize = %d\n", reportDataSize);
#endif
    // Convert reportData from byte array to string
    char reportDataStr[(reportDataSize * 2) + 1];
    memset(reportDataStr,0,sizeof(reportDataStr)); 
    char *ptr = &reportDataStr[0];
    for(i=0;i<reportDataSize;i++) { 
        ptr += sprintf(ptr, "%02x", reportData[i]);
    }
#if DEBUG
    printf("reportDataStr = %s\n", reportDataStr);
#endif

    // Get Hostname and Port from environment
    char *h = getenv("SENSORIANT_ATTESTATION_HOST");
    if (!h) {
	h = "senslas";
    }
    char *p = getenv("SENSLAS_PORT");
    if (!p) {
        p = "9004";
    }


    // Prepare URL
    args[1] = h;
    args[2] = p;
    args[3] = "POST";
    // get Signed report
    args[4] = "/SignReportEDDSA";
    args[5] = "keyHandleId=0&nvramId=0&reportData=";
    char urlparams[4096];
    strcpy(urlparams, args[5]);
    strcat(urlparams,reportDataStr);
    args[5] = urlparams;
    char urlparams2[4096];
    strcpy(urlparams2, args[4]);
    strcat(urlparams2,"?");
    strcat(urlparams2,args[5]);
    args[4] = urlparams2;

#if DEBUG
    printf("\n\nURL = %s", urlparams2);
#endif
 
    // Send to Server
    memset(resp,0,sizeof(resp));
    httpclient(6,args,resp);

    // Parse Response
    char *jsonStart = strstr(resp, "{");
    if ( !jsonStart )
    {
        printf("Invalid Response fron SensLAS");
    }
    else
    {
        char *ret;
        ret = strstr(resp, "{");
#if DEBUG
        printf("\n\nSigned Report: \n");
        printf("json=%s",ret);
#endif
        jsmn_parser p;
        jsmntok_t t[128]; /* We expect no more than 128 tokens */

        jsmn_init(&p);

        r = jsmn_parse(&p, ret, strlen(ret), t, sizeof(t) / sizeof(t[0]));
        if (r < 0) {
            printf("Failed to parse JSON: %d\n", r);
            return 1;
        }
    
        // Get Signature as string from response
        uint8_t signatureStr[128+1];
        memset(signatureStr,0,sizeof(signatureStr));
        for (i = 1; i < r; i++) {
            if (jsoneq(ret, &t[i], "signature") == 0) {
                sprintf(signatureStr, "%.*s", t[i + 1].end - t[i + 1].start, ret + t[i + 1].start);
#if DEBUG
                printf("\n\nsignatureStr=%s\n",signatureStr);
#endif
                    i++;
             } else if (jsoneq(ret, &t[i], "rawDigest") == 0) {
                sprintf(rd, "%.*s", t[i + 1].end - t[i + 1].start, ret + t[i + 1].start);
#if DEBUG
                printf("\n\nraw digest=%s\n",rd);
#endif
                    i++;
             }
        }

        // Convert signature to byte array
         /* WARNING: no sanitization or error-checking whatsoever */
        uint8_t *pos = signatureStr;
        for (size_t count = 0; count < 64; count++) {
            sscanf(pos, "%2hhx", &signature[count]);
            pos += 2;
        }
    }
#if DEBUG
    printf("Exiting signReportEDDSA..\n");
    printf("---------------------------------\n");
#endif
    return 0;
}

//
// Get EDDSA Public Key from SensLAS
//
bool getPlatformEDDSAKey (char *pubkey)
{
    int i;
    int r;
    char resp[4096];
    char *args[7];

    // Get Hostname and Port from environment
    char *h = getenv("SENSORIANT_ATTESTATION_HOST");
    if (!h) {
	h = "senslas";
    }
    char *p = getenv("SENSLAS_PORT");
    if (!p) {
        p = "9004";
    }
#if DEBUG
    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Entering getPlatformEDDSAKey..\n");
#endif

    args[1] = h;
    args[2] = p;
    args[3] = "POST";
    args[4] = "/GetPlatformEDDSAKey";
    args[5] = "keyHandleId=0&nvramId=0";
    char urlparams[4096];
    strcpy(urlparams, args[4]);
    strcat(urlparams,"?");
    strcat(urlparams,args[5]);
    args[4] = urlparams;
    args[6] = "Content-Type: application/x-www-form-urlencoded";

    // Send to Server
    memset(resp,0,sizeof(resp));
    httpclient(6,args,resp);
#if DEBUG
    printf("\nLUKE resp=\n%s",resp);
#endif
    // Parse response
    char *jsonStart = strstr(resp, "{");
    if ( !jsonStart )
    {
        printf("Invalid Response");
    }
    else
    {
        char *ret;
        ret = strstr(resp, "{");
        jsmn_parser p;
        jsmntok_t t[128]; /* We expect no more than 128 tokens */

        jsmn_init(&p);
        r = jsmn_parse(&p, ret, strlen(ret), t, sizeof(t) / sizeof(t[0]));
        if (r < 0) {
            printf("Failed to parse JSON: %d\n", r);
            return 1;
        }
        
        // Get Public Key as string
        char pubKeyStr[64+1];
        memset(pubKeyStr,0,sizeof(pubKeyStr));
        for (i = 1; i < r; i++) {
            if (jsoneq(ret, &t[i], "platformSigningKey") == 0) {
                sprintf(pubKeyStr, "%.*s", t[i + 1].end - t[i + 1].start, ret + t[i + 1].start);
                    i++;
                }
        }
#if DEBUG
        printf ("\n\nLUKE: pubKeyStr = %s\n\n", pubKeyStr);
#endif
        // Convert to byte array
         /* WARNING: no sanitization or error-checking whatsoever */
        char *pos = pubKeyStr;
        for (size_t count = 0; count < 32; count++) {
            sscanf(pos, "%2hhx", &pubkey[count]);
            pos += 2;
        }
    }
}

//
// create_report Native Attestation Hook
//
scone_rt_hook_status_t scone_rt_hook_scone_attestation_create_report(const scone_sgx_target_info_t *target_info, const scone_sgx_report_data_t *report_data, scone_sgx_report_t *report) {

    printf("Entering create_report native attestation hook..\n");	
    uint8_t *p, *q;
    //////////////////////////////////////////////
    // DEBUG
    //
#if DEBUG
    printf("---------------------------------\n");
    printf("Entering create_report..\n");
    printf("---------------------------------\n");
#endif

    int pid = getpid();
#if DEBUG
    printf("Process ID = %d\n", pid);
#endif
    getProcessMeasurement(pid, report->body.mrenclave);
    char *mode = getenv("SENS_HASH");
    if (!mode) {
#if DEBUG	    
	printf ("Normal Mode\n");
#endif	
    }
    else {
    // Convert report->body.mrenclave back to string and print out	    
    	char measurementStr[sizeof(report->body.mrenclave) * 2 + 1];
    	memset(measurementStr,0,sizeof(measurementStr));
    	char *ptr = &measurementStr[0];
    	for(int i=0;i<sizeof(report->body.mrenclave);i++) {
        	ptr += sprintf(ptr, "%02x", report->body.mrenclave[i]);
    	}
	printf ("%s\n", measurementStr);
	exit(0);
    }	
    report->body.attributes.init = 1;

    //////////////////////////////////////////////
    // DEBUG
    //
#if DEBUG
    printf("---------------------------------\n");
    printf("report->body.mrenclave = ");
    p = (uint8_t *)&report->body.mrenclave;
    for (int i = 0; i < sizeof(report->body.mrenclave); i++) {
        printf("%02X ",p[i]);
    }
    printf("\n");
    printf("---------------------------------\n");
#endif
    //
    // Copy report data to output
    //
    p = (uint8_t *)&report->body.reportdata;
    q = (uint8_t *)report_data;
    for (int i=0; i<64;i++) {
        *p++=*q++;
    }

#if DEBUG
    printf ("Output: report = \n");
    p = (uint8_t *)report;
    printf ("Size of nsgx_report_t = %d\n", sizeof(scone_sgx_report_t));
    for (int i=0; i<sizeof(scone_sgx_report_t); i++) {
        printf("%02X",p[i]);
    }

    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Exiting create_report..\n");
    printf("---------------------------------\n");
#endif    
    return SCONE_HOOK_STATUS_SUCCESS;
}

//
// create_quote Native Attestation Hook
//
scone_rt_hook_status_t scone_rt_hook_scone_attestation_create_quote(const scone_sgx_report_t *report, scone_sgx_scone_quote_t *quote) {

    printf("Entering create_quote native attestation hook..\n");
#if DEBUG
    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Entering create_quote..\n");
    printf("report->body:\n");
    uint8_t *r = (uint8_t *)&report->body;
    for (int i = 0; i < sizeof(report->body); i++) {
        printf("%02x ",r[i]);
    }
    printf("\n\n");
    printf("quote->body:\n");
    uint8_t *q = (uint8_t *)&quote->body;
    for (int i = 0; i < sizeof(quote->body); i++) {
        printf("%02x ",q[i]);
    }
    printf("\n");
    printf("---------------------------------\n");    
    //////////////////////////////////////////////
#endif

#if DEBUG
    printf("---------------------------------\n");
    printf("Calling GetPlatformEDDSAKey\n");
#endif
    getPlatformEDDSAKey(quote->public_key);
    // Convert reportData from byte array to string
    char publicKeyStr[(32 * 2) + 1];
    memset(publicKeyStr,0,sizeof(publicKeyStr));
    char *ptr = &publicKeyStr[0];
    for(int i=0;i<32;i++) {
        ptr += sprintf(ptr, "%02x", quote->public_key[i]);
    }
#if DEBUG
    printf("\n\nSensoriant Public Key (string): %s\n", publicKeyStr);
    printf("\nDone\n");
    printf("---------------------------------\n");
    printf("---------------------------------\n");
    printf("Calling SignReportEDDSA\n");
#endif
    uint8_t *p = (uint8_t *)&report->body;
    signReportEDDSA((uint8_t *)&report->body, sizeof(report->body), quote->signature);
    // Convert signature from byte array to string
    char signatureStr[(64 * 2) + 1];
    memset(signatureStr,0,sizeof(signatureStr));
    ptr = &signatureStr[0];
    for(int i=0;i<64;i++) {
        ptr += sprintf(ptr, "%02x", quote->signature[i]);
    }
#if DEBUG
    printf("\n\nSensoriant Signature (string): %s\n", signatureStr);
    printf("\nDone\n");
    printf("---------------------------------\n");
#endif
    // Update quote->body
    quote->body = report->body;

#if DEBUG
    //////////////////////////////////////////////
    // DEBUG
    //
    printf("---------------------------------\n");
    printf("Exiting create_quote..\n");
    printf("report->body:\n");
    for (int i = 0; i < sizeof(report->body); i++) {
        printf("%02x ",r[i]);
    }
    printf("\n\n");
    printf("quote->body:\n");
    for (int i = 0; i < sizeof(quote->body); i++) {
        printf("%02x ",q[i]);
    } 
    printf("\n");
    printf("---------------------------------\n");
    /////////////////////////////////////////////
#endif
    return SCONE_HOOK_STATUS_SUCCESS;
}
