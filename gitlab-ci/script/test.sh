#! /bin/bash

function deploy() {
  track="${1:-stable}"
  percentage="${2:-100}"

  echo tarck=${track}
  echo percentage=${percentage}
}

deploy rollout  
