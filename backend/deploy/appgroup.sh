for kservice in $(oc get ksvc -o jsonpath='{.items[*].metadata.name}');
do
  oc label ksvc $kservice app.kubernetes.io/part-of=battleships-functions
done