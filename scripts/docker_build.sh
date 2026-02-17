#!/bin/bash

# Runs inside the manylinux Docker container.
# Builds binary wheels for supported Python versions.

set -e -x

# Install OpenSSL development headers for DTLS support
yum install -y openssl-devel || dnf install -y openssl-devel || true

# Build wheels for Python 3.10 - 3.13
for PYBIN in /opt/python/{cp39-cp39,cp310-cp310,cp311-cp311,cp312-cp312,cp313-cp313,cp314-cp314}/bin; do
    if [ -d "$PYBIN" ]; then
        "${PYBIN}/pip" install --upgrade pip setuptools "Cython>=3,<4"
        cd /io/
        "${PYBIN}/python" setup.py bdist_wheel -d /wheelhouse/
        cd /
    fi
done

# Bundle external shared libraries into the wheels
for whl in /wheelhouse/*.whl; do
    auditwheel repair "$whl" -w /io/wheelhouse/
done

echo "Wheels built in /io/wheelhouse/"
