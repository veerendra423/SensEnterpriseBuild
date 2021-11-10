#!/bin/bash
source ./.env
RELEASE_TAG=${RELEASE_TAG}

attest()
{
    echo "In attest()"
    docker-compose run SensLAS /SensAttest/SensAttest attest
    echo "Done.."
}

create_internal_key()
{
    echo "In create_internal_key()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 create-load-internal-key
    echo "Done.."
}

get_platform_id()
{
    echo "In get_platform_id()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 GetPlatformId
    echo "Done.."
}

get_platform_eddsa_key()
{
    echo "In get_platoform_eddsa_key()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 GetPlatformEDDSAKey
    echo "Done.."
}

get_platform_signing_key()
{
    echo "In get_platform_signing_key()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 GetPlatformSigningKey
    echo "Done.."
}

get_platform_encryption_key()
{   
    echo "In get_platform_encryption_key()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 GetPlatformEncryptionKey
    echo "Done.."
}

sign_quote()
{
    echo "In sign_quote()"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 SignQuote
    echo "Done.."
}

decrypt()
{
    echo "In decrypt()"
    echo "This only works on sensdevel2 machine in Google"
    docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 -encryptedData=d+GO0q80Xrwajb2bqi7bnC6yJD/FH48W1J+sRUhScy/nl4AVLBV92d0qYCnRxliwUA9fHBSfvB/NPW3C3xUQOU1w52O8mYQPWf93PX4YaX6nm8DkkvJW5U+A8vGAowuxGBDj9M6wu9DGJffVgfQJ1hrbtgW29qR7ngCkiV3cocFsKJYs3RUoA9Le4vn/04z97Y1qpQRxM4/Pg6TsTxM1pY4HkItelT0zSE/CMQXclZwpvTLT9oqtOC/xoSHxcd5AWFG/0vM+rXPDALQgLOJp+g57v5rWg8rHuLFwr+nFYtISciWOZMmx5kANqjZqA4Op6rneSLlH/FPYVgsQh2djDA== Decrypt
    echo "Done.."
}

show_options()
{
    echo "-------------------------------------------"
    echo "Sensoriant TPM test: $RELEASE_TAG" 
    echo "-------------------------------------------"
    PS3='Please enter your choice: '
    options=("Attest" "Create Internal Key" "Get Platform Id" "Get Platform EDDSA Key" "Get Platform Signing Key" "Get Platform Encryption Key" "Sign Quote" "Decrypt" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Attest")
             echo "Attesting Machine"; attest
             ;;
            "Create Internal Key")
             echo "Creating Internal Key"; create_internal_key
             ;;
            "Get Platform Id")
             echo "Getting PLatform Id"; get_platform_id
             ;;
            "Get Platform EDDSA Key")
             echo "Getting Platform EDDSA Key"; get_platform_eddsa_key
             ;;
            "Get Platform Signing Key")
             echo "Getting Platform Signing Key"; get_platform_signing_key
             ;;
            "Get Platform Encryption Key")
             echo "Getting Platform Encryption Key"; get_platform_encryption_key
             ;;
            "Sign Quote")
             echo "Signing Quote";sign_quote
             ;;
            "Decrypt")
             echo "Decrypting";decrypt
             ;;
            "Quit")
                break
                ;;
            *) 
            PS3="" # this hides the prompt
                echo asdf | select foo in "${options[@]}"; do break; done # dummy select
                PS3="Please enter your choice: " # this displays the common prompt
                ;;
        esac
    done
}

show_options
