#!/bin/sh -x

./victoria-metrics-prod &
PID_VM=$!

TARGET_TIME=$(date -d '-1 hour' +"%Y-%m-%dT%H")
export TARGET_TIME

for file in ./data/*; do
  if [ -f "$file" ]; then
    echo "Processing $file"
    envsubst <$file >"$file.tmp" && mv "$file.tmp" "$file"
  fi
done

until nc -z localhost $VM_PORT; do
  echo "Waiting for VictoriaMetrics..."
  sleep 1
done

VM_URL="http://localhost:$VM_PORT/api/v1/import/csv?format=1:time:rfc3339"
curl "$VM_URL,2:label:job,3:label:fruit_name,4:label:fruit_color,5:label:fruit_size,6:metric:fruit_sold_count" -T ./data/data_fruit_sold_count.csv
curl "$VM_URL,2:label:job,3:label:student_name,4:label:fruit_name,5:metric:student_has_fruit_allergy" -T ./data/data_student_has_fruit_allergy.csv
curl "$VM_URL,2:label:job,3:label:student_name,4:label:fruit_name,5:metric:student_favorite_fruit_score" -T ./data/data_student_favorite_fruit_score.csv
curl "$VM_URL,2:label:job,3:label:child_name,4:label:name,5:label:gender,6:label:phone,7:label:age,8:label:email,9:metric:parent_info" -T ./data/data_parent_info.csv
curl "http://localhost:$VM_PORT/internal/force_flush" \

trap "echo 'Stopping...'; kill $PID_VM; wait $PID_VM; exit" TERM INT
wait $PID_VM
