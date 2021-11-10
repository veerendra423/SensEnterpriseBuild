#!/usr/bin/bats

setup () {
    if [ ! -z "$ONLY_TEST" ] && [ "$BATS_TEST_NUMBER" != "$ONLY_TEST" ]; then
        skip
    fi
}

@test "[$BATS_TEST_NUMBER] hello message" {
    echo "BATS> Compiling source code"
    make with-scone
    run ./copy_files -h
    [ "$status" -eq 0 ]
    echo "BATS> Removing source file and executable"
    make clean
}

@test "[$BATS_TEST_NUMBER] only files" {
    echo "BATS> Compiling source code"
    make with-scone
    mkdir input output
    for i in {1..5}
    do
       touch input/file${i}
    done
    run ./copy_files -i input -o output
    [ "$status" -eq 0 ]
    echo "BATS> Removing source file and executable"
    make clean
    rm -r input output
}

@test "[$BATS_TEST_NUMBER] only folders" {
    echo "BATS> Compiling source code"
    make with-scone
    for i in {1..5}
    do
       mkdir -p input/input${i}
    done
    mkdir output
    run ./copy_files -i input -o output
    diff input output
    [ "$status" -eq 0 ]
    echo "BATS> Removing source file and executable"
    make clean
    rm -r input output
}

@test "[$BATS_TEST_NUMBER] one file per folder" {
    echo "BATS> Compiling source code"
    make with-scone
    for i in {1..5}
    do
       mkdir -p input/input${i}
       touch input/input${i}/file${i} 
    done
    touch input/top
    mkdir output
    run ./copy_files -i input -o output
    diff input output
    [ "$status" -eq 0 ]
    echo "BATS> Removing source file and executable"
    make clean
    rm -r input output
}

@test "[$BATS_TEST_NUMBER] copy /bin directory " {
    echo "BATS> Compiling source code"
    make with-scone
    mkdir output
    run ./copy_files -i /bin -o output
    diff /bin output
    [ "$status" -eq 0 ]
    echo "BATS> Removing source file and executable"
    make clean
    rm -r output
}