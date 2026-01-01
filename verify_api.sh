#!/bin/bash

BASE_URL="http://localhost:8080"

echo "1. Create Student"
curl -X POST "$BASE_URL/students" -d '{"name": "John Doe", "age": 20, "grade": "A"}' -H "Content-Type: application/json"
echo -e "\n"

echo "2. Get Students"
curl "$BASE_URL/students"
echo -e "\n"

# Assuming the first student has ID 1
STUDENT_ID=1

echo "3. Create Subject"
curl -X POST "$BASE_URL/subjects" -d '{"name": "Mathematics", "code": "MATH101"}' -H "Content-Type: application/json"
echo -e "\n"

echo "4. Get Subjects"
curl "$BASE_URL/subjects"
echo -e "\n"

# Assuming the first subject has ID 1
SUBJECT_ID=1

echo "5. Create Mark"
curl -X POST "$BASE_URL/marks" -d "{\"student_id\": $STUDENT_ID, \"subject_id\": $SUBJECT_ID, \"score\": 95.5}" -H "Content-Type: application/json"
echo -e "\n"

echo "6. Get Marks"
curl "$BASE_URL/marks"
echo -e "\n"

echo "6b. Get Marks for Student $STUDENT_ID"
curl "$BASE_URL/marks?student_id=$STUDENT_ID"
echo -e "\n"

echo "7. Create Fee"
curl -X POST "$BASE_URL/fees" -d "{\"student_id\": $STUDENT_ID, \"amount\": 500.0, \"status\": \"pending\"}" -H "Content-Type: application/json"
echo -e "\n"

echo "8. Get Fees"
curl "$BASE_URL/fees"
echo -e "\n"

echo "9. Initialize Tables (manual trigger via any request if lazy loaded, or assuming init happened)"
# In my implementation, I didn't auto-call ensureTablesExist. I should probably add a temporary route to trigger it or modifying the code to auto-init.
# Let's check DatabaseClient again. It has ensureTablesExist but it is not called.
# I will add a call to ensureTablesExist in the first route handler or middleware to be safe, 
# OR I will add a specific file to run for initialization.

# For now, I will modify the script to print a warning if tables/db are not set up.
