#!/bin/bash

# Variables
NAMESPACE="cp4ba-collateral"
STATEFULSET="postgresql"
DEPLOYMENT="openldap"
POSTGRES_IMAGE="docker.io/bitnamilegacy/postgresql:15.8.0-debian-12-r26"
OPENLDAP_IMAGE="docker.io/bitnamilegacy/openldap:2.6.9-debian-12-r14"

echo "🔻 Scaling down Deployment $DEPLOYMENT..."
oc scale deployment "$DEPLOYMENT" --replicas=0 -n "$NAMESPACE"

echo "🔻 Scaling down StatefulSet $STATEFULSET..."
oc scale statefulset "$STATEFULSET" --replicas=0 -n "$NAMESPACE"

echo "⏳ Waiting for pods to terminate..."
oc wait --for=delete pod -l app="$STATEFULSET" -n "$NAMESPACE" --timeout=120s
oc wait --for=delete pod -l app="$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s

echo "🛠️ Patching image in StatefulSet $STATEFULSET..."
oc patch statefulset "$STATEFULSET" -n "$NAMESPACE" \
  --type='json' \
  -p="[{'op': 'replace', 'path': '/spec/template/spec/containers/0/image', 'value': '$POSTGRES_IMAGE'}]"

echo "🛠️ Patching image in Deployment $DEPLOYMENT..."
oc patch deployment "$DEPLOYMENT" -n "$NAMESPACE" \
  --type='json' \
  -p="[{'op': 'replace', 'path': '/spec/template/spec/containers/0/image', 'value': '$OPENLDAP_IMAGE'}]"

echo "🔼 Scaling up StatefulSet $STATEFULSET..."
oc scale statefulset "$STATEFULSET" --replicas=1 -n "$NAMESPACE"

echo "🔼 Scaling up Deployment $DEPLOYMENT..."
oc scale deployment "$DEPLOYMENT" --replicas=1 -n "$NAMESPACE"

echo "⏳ Waiting for StatefulSet $STATEFULSET to be ready..."
oc rollout status statefulset "$STATEFULSET" -n "$NAMESPACE"

echo "⏳ Waiting for Deployment $DEPLOYMENT to be ready..."
oc rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE"

echo "✅ All resources updated and ready!"