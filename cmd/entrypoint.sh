#! /usr/bin/env bash
if [[ "$1" == "smoke" ]]; then
    echo "Running smoke tests..."
    /src/app/smoke_test.py ${@:2} #just pass along the arguments after smoke | functional.
elif [[ "$1" == "functional" ]]; then
    echo "Running functional tests..."
    /src/app/functional_test.py ${@:2} #just pass along the arguments after smoke | functional.
else
    echo "Unsupported test type"
fi