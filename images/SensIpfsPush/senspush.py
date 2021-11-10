import prefect
from prefect import task, Flow, Parameter
import time
import subprocess
from subprocess import Popen, PIPE

#
# Two tasks in this Push Component
# Task 1 shells out to a Javascript proram which does the following:
#  - Get Encryption Key from the Decrypt Policy in CAS
#
# Task 2 shells out to a Go program which does the following
#  - Do the actual encryption
#  - Send the output to IPFS
# Flow registers with Prefect Serverd on Controller
# Agent is launched and it waits for work to be done
# Once pipeline is kicked off this flow will be invoked
# When complete the Component goes back to sleep to wait for more work
#
@task
def senspushGetPublicKey(parm):
    logger = prefect.context.get("logger")
    logger.info("Luke: In senspushGetPublicKey, parm = %s", parm)
    logger.info("Luke: Getting Public Key...")
    shell_cmd = (['ts-node', "/app/app.ts", "read"])
    process = Popen(shell_cmd, stdout=PIPE)
    for line in process.stdout:
        logger.info(line.decode())
    process.stdout.close()
    return_code = process.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, shell_cmd)
    return True

@task
def senspushEncrypt(rc, parm):
    logger = prefect.context.get("logger")
    logger.info("Luke: In senspushEncrypt, parm = %s", parm)
    logger.info("Luke: Encrypting...")
    outputDirArg = "-o=" + parm
    shell_cmd = (['./encrypt', "-ne", "-k=/keys/encrypt.pub", "-i=/projects/encrypt-input/", outputDirArg])
    process = Popen(shell_cmd, stdout=PIPE)
    for line in process.stdout:
        logger.info(line.decode())
    process.stdout.close()
    return_code = process.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, shell_cmd)
    return True

with Flow("sensencrypt") as flow:
    pipeline_input = Parameter("flow_run_name", default="none")
    rc = senspushGetPublicKey(pipeline_input)
    senspushEncrypt(rc, pipeline_input)

#
# Register flow with Pipeline Manager (Prefect Server) and launch Agent
#
flow.register()
flow.run_agent()
#flow.run(flow_run_name = "abcde")
