#
# One time configuration of TPM for each new machine deployed
#
docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 create-load-internal-key
docker-compose run SensLAS /SensAttest/SensAttest -nvramIndex=0 -keyHandleId=0 create-load-eddsa-key

