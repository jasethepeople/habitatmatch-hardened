#!/usr/bin/env bash
set -euo pipefail
: "${STRIPE_SECRET_KEY:?Set STRIPE_SECRET_KEY}"
base='https://api.stripe.com/v1'
create_product(){ curl -fsS -u "$STRIPE_SECRET_KEY:" "$base/products" -d "name=$1" -d "metadata[role]=housing_provider"; }
create_price(){ curl -fsS -u "$STRIPE_SECRET_KEY:" "$base/prices" -d "product=$1" -d "unit_amount=$2" -d currency=usd -d 'recurring[interval]=month'; }
for spec in 'Starter:9900' 'Growth:29900' 'Scale:79900'; do name=${spec%%:*}; amount=${spec##*:}; product=$(create_product "HabitatMatch $name"); pid=$(printf '%s' "$product" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'); price=$(create_price "$pid" "$amount"); prid=$(printf '%s' "$price" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'); echo "STRIPE_PRICE_${name^^}=$prid"; done
