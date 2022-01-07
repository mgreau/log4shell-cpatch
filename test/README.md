
Test the steps.
```
docker build . -t cpatch-test

docker run -it cpatch-test
root@05863bb11851:/# /usr/local/bin/cpatch-steps-test.sh
```