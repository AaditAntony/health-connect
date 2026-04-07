import os
import re

files_to_process = [
    "lib/admin/admin_payments_page.dart",
    "lib/admin/overview_tab.dart",
    "lib/admin/approved_hospitals_tab.dart",
    "lib/admin/pending_request_tab.dart",
    "lib/admin/hospital_detail_page.dart",
    "lib/admin/auth_wrapper.dart",
    "lib/hospital/patient_ai_summary_page.dart",
    "lib/hospital/overview_tab.dart",
    "lib/hospital/add_patient_list.dart",
    "lib/hospital/data_requests_tab.dart",
    "lib/hospital/test_appointments_tab.dart",
    "lib/hospital/shared_patient_records_page.dart",
    "lib/hospital/hospital_verification_page.dart",
    "lib/hospital/hospital_overview_tab.dart",
    "lib/hospital/patient_records_tab.dart",
    "lib/patient/patient_smartcare_plan_page.dart",
    "lib/patient/book_consultation_page.dart",
    "lib/patient/patient_consent_page.dart",
    "lib/patient/book_hospital_test_page.dart",
    "lib/patient/patient_medical_history_page.dart",
    "lib/patient/patient_appointments_tab.dart"
]

for file_path in files_to_process:
    full_path = os.path.join('/Users/aaditantony/health_connect', file_path)
    if not os.path.exists(full_path):
        print(f"Skipping {file_path}")
        continue

    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()

    def replace_custom_snapshot(match):
        pre = match.group(1)
        snapshot_name = match.group(2)
        
        search_region = content[match.end():match.end()+300]
        if f"{snapshot_name}.hasError" in search_region:
            return pre
            
        snip = f"""
        if ({snapshot_name}.hasError) {{
          debugPrint("Error: ${{{snapshot_name}.error}}");
          return Center(child: Text("Error: \\n${{{snapshot_name}.error}}", textAlign: TextAlign.center));
        }}"""
        
        snip_auth = f"""
        if ({snapshot_name}.hasError) {{
          debugPrint("Error: ${{{snapshot_name}.error}}");
          return Scaffold(body: Center(child: Text("Error: \\n${{{snapshot_name}.error}}", textAlign: TextAlign.center)));
        }}"""
        
        if "auth_wrapper" in file_path:
            return pre + snip_auth
        else:
            return pre + snip

    new_content = re.sub(
        r'(builder:\s*\([^,]+,\s*(?:[a-zA-Z<>0-9_\?]+\s+)?([a-zA-Z0-9_]+)\)\s*\{)',
        replace_custom_snapshot, 
        content
    )

    if new_content != content:
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated {file_path}")
    else:
        print(f"No changes in {file_path}")

