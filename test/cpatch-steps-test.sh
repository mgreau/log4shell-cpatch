
#!/bin/bash 

crane export elasticsearch:6.8.18 image_content.tar

mkdir -p /wk/storage/image_content

tar -xf image_content.tar -C /wk/storage/image_content

log4jscanner /wk/storage/image_content >> /wk/storage/jars-detected.txt

cat /wk/storage/jars-detected.txt

log4jscanner --rewrite  /wk/storage/image_content

tar -cvf /wk/storage/log4shell-patch.tar --absolute-names --files-from /wk/storage/jars-detected.txt

tar --transform 's,^/wk/storage/image_content,,' -c  -f /wk/storage/log4shell-patch.tar --files-from /wk/storage/jars-detected.txt --show-transformed-names --absolute-names

tar --list --verbose --absolute-names --file=/wk/storage/log4shell-patch.tar

IMAGE_NAME=$(date +%Y%m%d%H%M%S)

crane append  -b mgreau/log4shell-cpatch-demo:1.0 -t ttl.sh/${IMAGE_NAME}:1h -f /wk/storage/log4shell-patch.tar -o /wk/storage/image_patched.tar

crane push /wk/storage/image_patched.tar ttl.sh/${IMAGE_NAME}:1h
 