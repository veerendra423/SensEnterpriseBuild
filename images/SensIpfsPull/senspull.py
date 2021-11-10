import prefect
from prefect import task, Flow, Parameter
import time
import subprocess
from subprocess import Popen, PIPE

#
# Single task in this Pull Component
# Task shells out to a Go process that does the following:
# 1. Get Decryption Private Key
# 2. Get data to decrypt form IPFS
# 3. Do the actual decryption
# Flow registers with Prefect Server on Controller
# Agent is launched and it waits for work to be done
# Once pipeline is kicked off this flow will be invoked
# When complete the Component goes back to sleep to wait for more work
#
@task
def senspullPull(parm):
    logger = prefect.context.get("logger")
    logger.info("Luke: In senspullPull, parm = %s", parm)
    logger.info("Luke: Pulling...")
    inputDirArg = "-i=" + parm
    shell_cmd = (['./decrypt', "-nd", "-k=/keys/decrypt/privateCryptoKey.key", "-o=/projects/decrypt-output/", inputDirArg])
    process = Popen(shell_cmd, stdout=PIPE)
    for line in process.stdout:
        logger.info(line.decode())
    process.stdout.close()
    return_code = process.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, shell_cmd)
    return True

with Flow("sensdecrypt") as flow:
    pipeline_input = Parameter("flow_run_name", default="none")
    senspullPull(pipeline_input)

#
# Register flow with Pipeline Manager (Prefect Server) and launch Agent
#
flow.register()
flow.run_agent()
#flow.run(flow_run_name = "abcde")
