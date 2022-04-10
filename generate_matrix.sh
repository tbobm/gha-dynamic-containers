targets=$(find -name Dockerfile)

echo "target:"
for target in $targets
do
    cat <<EOF
  - src: ${target%/*}
    name: $target
EOF
done
