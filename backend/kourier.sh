kourier_version="v0.20.0"

function header_text {
  echo "$header$*$reset"
}

header_text "Using Kourier Version:                      ${kourier_version}"

header_text "Setting up Kourier"
kubectl apply -f "https://github.com/knative/net-kourier/releases/download/${kourier_version}/kourier.yaml"

header_text "Waiting for Kourier to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system

header_text "Configure Knative Serving to use the proper 'ingress.class' from Kourier"
kubectl patch configmap/config-network \
  -n knative-serving \
  --type merge \
  -p '{"data":{"clusteringress.class":"kourier.ingress.networking.knative.dev",
               "ingress.class":"kourier.ingress.networking.knative.dev"}}'