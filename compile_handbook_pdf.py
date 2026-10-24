# -*- coding: utf-8 -*-
"""
Compiles all 21 handbook markdown files into a styled HTML document and renders
LEO_OPUS_INTERVIEW_HANDBOOK.pdf using Microsoft Edge headless.
"""
import os
import subprocess
import re

BASE_DIR = r"d:\Shinnovation\leox"
DOCS_DIR = os.path.join(BASE_DIR, "LEO_OPUS_INTERVIEW_PREPARATION")
OUTPUT_HTML = os.path.join(DOCS_DIR, "LEO_OPUS_MASTER_HANDBOOK.html")
OUTPUT_PDF = os.path.join(BASE_DIR, "LEO_OPUS_INTERVIEW_HANDBOOK.pdf")

ORDERED_FILES = [
    "README.md",
    "00_PROJECT_OVERVIEW.md",
    "01_ARCHITECTURE_AND_DATA_FLOW.md",
    "02_FLUTTER_AND_DART.md",
    "03_BACKEND_AND_REST_APIS.md",
    "04_DATABASES_AND_DBMS.md",
    "05_DSA_AND_ALGORITHMS.md",
    "06_OOP_AND_JAVA.md",
    "07_OPERATING_SYSTEMS.md",
    "08_COMPUTER_NETWORKS_AND_SECURITY.md",
    "09_SOFTWARE_ENGINEERING_AND_SDLC.md",
    "10_SYSTEM_DESIGN.md",
    "11_AUTHENTICATION_AND_SECURITY_AUDIT.md",
    "12_GEMINI_AI_AND_RESUME_MATCHING.md",
    "13_RAZORPAY_AND_SUBSCRIPTIONS.md",
    "14_DEPLOYMENT_DEVOPS_AND_MAINTENANCE.md",
    "15_TESTING_AND_DEBUGGING.md",
    "16_HR_AND_BEHAVIOURAL_ANSWERS.md",
    "17_CORE_SUBJECTS_TO_PROJECT_MAPPING.md",
    "18_TOP_30_TECHNICAL_QUESTIONS.md",
    "19_FINAL_MOCK_INTERVIEW.md",
    "20_GAPS_AND_CLARIFICATION_QUESTIONS.md",
]

def md_to_html(md_text):
    # Basic markdown to clean HTML conversion
    html = md_text
    
    # Escape HTML special chars except already formatted tags
    # Handle headings
    html = re.sub(r'^# (.+)$', r'<h1 class="chapter-title">\1</h1>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', html, flags=re.MULTILINE)
    
    # Handle bold and italic
    html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
    html = re.sub(r'\*(.+?)\*', r'<em>\1</em>', html)
    
    # Handle blockquotes
    html = re.sub(r'^> (.+)$', r'<blockquote>\1</blockquote>', html, flags=re.MULTILINE)
    
    # Handle code blocks
    html = re.sub(r'```([a-zA-Z0-9_\-]+)?\n([\s\S]+?)```', r'<pre><code>\2</code></pre>', html)
    html = re.sub(r'`([^`\n]+)`', r'<code>\1</code>', html)
    
    # Handle horizontal rules
    html = re.sub(r'^---$', r'<hr/>', html, flags=re.MULTILINE)
    
    # Handle tables
    lines = html.split('\n')
    in_table = False
    table_lines = []
    output_lines = []
    
    for line in lines:
        if line.strip().startswith('|') and line.strip().endswith('|'):
            if not in_table:
                in_table = True
                table_lines = [line]
            else:
                table_lines.append(line)
        else:
            if in_table:
                in_table = False
                # Convert table_lines to HTML table
                output_lines.append(render_table(table_lines))
                table_lines = []
            output_lines.append(line)
    if in_table:
        output_lines.append(render_table(table_lines))
        
    html = '\n'.join(output_lines)
    
    # Convert unordered lists
    html = re.sub(r'^- (.+)$', r'<li>\1</li>', html, flags=re.MULTILINE)
    # Wrap lists
    html = re.sub(r'(<li>.+?</li>(\n<li>.+?</li>)*)', r'<ul>\1</ul>', html)
    
    # Convert paragraphs
    paragraphs = []
    for block in html.split('\n\n'):
        block = block.strip()
        if not block:
            continue
        if any(block.startswith(t) for t in ['<h1', '<h2', '<h3', '<h4', '<pre', '<table', '<ul', '<hr', '<blockquote']):
            paragraphs.append(block)
        else:
            paragraphs.append(f"<p>{block.replace(chr(10), '<br/>')}</p>")
            
    return '\n\n'.join(paragraphs)

def render_table(table_lines):
    if len(table_lines) < 2:
        return '\n'.join(table_lines)
    header_cols = [c.strip() for c in table_lines[0].strip().strip('|').split('|')]
    # skip separator line at index 1
    rows = []
    for line in table_lines[2:]:
        cols = [c.strip() for c in line.strip().strip('|').split('|')]
        rows.append(cols)
        
    html = ['<table class="data-table">']
    html.append('  <thead><tr>')
    for h in header_cols:
        html.append(f'    <th>{h}</th>')
    html.append('  </tr></thead>')
    html.append('  <tbody>')
    for r in rows:
        html.append('  <tr>')
        for idx, c in enumerate(r):
            html.append(f'    <td>{c}</td>')
        html.append('  </tr>')
    html.append('  </tbody></table>')
    return '\n'.join(html)

print("Reading and assembling all handbook chapters...")
all_html_chapters = []

for filename in ORDERED_FILES:
    filepath = os.path.join(DOCS_DIR, filename)
    if os.path.exists(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        chapter_html = md_to_html(content)
        all_html_chapters.append(f'<section class="chapter-page">\n{chapter_html}\n</section>')
    else:
        print(f"Warning: Missing file {filename}")

master_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>LEO OPUS — Complete Technical Interview Handbook</title>
<style>
  @page {{
    size: A4;
    margin: 18mm 14mm 18mm 14mm;
    @bottom-center {{
      content: counter(page);
    }}
  }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #1e293b;
    background: #ffffff;
    line-height: 1.55;
    font-size: 10.5pt;
  }}
  .cover-page {{
    text-align: center;
    padding: 120px 20px 80px 20px;
    page-break-after: always;
  }}
  .cover-title {{
    font-size: 28pt;
    font-weight: 800;
    color: #0f172a;
    letter-spacing: -0.5px;
    margin-bottom: 10px;
  }}
  .cover-subtitle {{
    font-size: 15pt;
    color: #2563eb;
    font-weight: 600;
    margin-bottom: 30px;
  }}
  .cover-meta {{
    font-size: 11pt;
    color: #475569;
    line-height: 1.8;
    margin-top: 50px;
    border-top: 2px solid #e2e8f0;
    padding-top: 30px;
    display: inline-block;
    text-align: left;
  }}
  .chapter-page {{
    page-break-after: always;
  }}
  h1.chapter-title {{
    color: #0f172a;
    font-size: 18pt;
    font-weight: 800;
    border-bottom: 2.5px solid #2563eb;
    padding-bottom: 8px;
    margin-top: 15px;
    margin-bottom: 15px;
  }}
  h2 {{
    color: #1e3a8a;
    font-size: 13.5pt;
    font-weight: 700;
    margin-top: 22px;
    margin-bottom: 10px;
    border-left: 4px solid #3b82f6;
    padding-left: 8px;
  }}
  h3 {{
    color: #0f172a;
    font-size: 11.5pt;
    font-weight: 700;
    margin-top: 16px;
    margin-bottom: 6px;
  }}
  p, li {{
    color: #334155;
  }}
  strong {{
    color: #0f172a;
  }}
  blockquote {{
    border-left: 4px solid #2563eb;
    background: #f8fafc;
    margin: 12px 0;
    padding: 10px 14px;
    color: #1e293b;
    font-style: italic;
  }}
  pre {{
    background: #0f172a;
    color: #f8fafc;
    padding: 12px;
    border-radius: 6px;
    font-size: 8.5pt;
    font-family: Consolas, "Courier New", monospace;
    overflow-x: auto;
    line-height: 1.4;
  }}
  code {{
    background: #f1f5f9;
    color: #0f172a;
    padding: 2px 5px;
    border-radius: 4px;
    font-size: 9pt;
    font-family: Consolas, monospace;
  }}
  pre code {{
    background: transparent;
    color: #f8fafc;
    padding: 0;
  }}
  table.data-table {{
    width: 100%;
    border-collapse: collapse;
    margin: 14px 0;
    font-size: 8.5pt;
  }}
  table.data-table th {{
    background: #1e293b;
    color: #ffffff;
    font-weight: 600;
    text-align: left;
    padding: 6px 8px;
    border: 1px solid #cbd5e1;
  }}
  table.data-table td {{
    padding: 5px 8px;
    border: 1px solid #e2e8f0;
    vertical-align: top;
  }}
  table.data-table tr:nth-child(even) {{
    background: #f8fafc;
  }}
  hr {{
    border: 0;
    border-top: 1px solid #cbd5e1;
    margin: 20px 0;
  }}
</style>
</head>
<body>

<div class="cover-page">
  <div class="cover-title">LEO OPUS</div>
  <div class="cover-subtitle">Complete Project Interview Handbook & LTIMindtree Master Preparation Guide</div>
  <p style="font-size: 12pt; color: #64748b; max-width: 600px; margin: 0 auto;">
    A comprehensive, evidence-based technical reference manual covering system architecture, full-stack Flutter & Node.js implementation, Cloud Firestore, Google Gemini AI, Razorpay payments, and core Computer Engineering fundamentals.
  </p>
  <div class="cover-meta">
    <strong>Author & Candidate:</strong> Akash Sanjay More<br/>
    <strong>Education:</strong> B.E. Computer Engineering, Sinhgad College of Engineering (SCOE), SPPU (CGPA: 8.54)<br/>
    <strong>Internship:</strong> Mobile Application Developer Intern at The Shinnovation Co.<br/>
    <strong>Target Role:</strong> Software Development Engineer / Graduate Engineer Trainee<br/>
    <strong>Date of Generation:</strong> October 2026<br/>
    <strong>Verification Standard:</strong> 100% Repository-Audited Source Code Evidence
  </div>
</div>

{''.join(all_html_chapters)}

</body>
</html>
"""

with open(OUTPUT_HTML, "w", encoding="utf-8") as f:
    f.write(master_html)
print(f"Master HTML written: {OUTPUT_HTML}")

# Render to PDF using Edge headless
edge_exe = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if os.path.exists(edge_exe):
    print("Invoking Microsoft Edge headless renderer to compile PDF...")
    cmd = [
        edge_exe,
        "--headless",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        f"--print-to-pdf={OUTPUT_PDF}",
        f"file:///{OUTPUT_HTML.replace(os.sep, '/')}"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(OUTPUT_PDF):
        size_mb = os.path.getsize(OUTPUT_PDF) / (1024 * 1024)
        print(f"SUCCESS: Generated PDF at {OUTPUT_PDF} ({size_mb:.2f} MB)")
    else:
        print(f"Edge execution finished. Output status: {res.returncode}")
else:
    print(f"Edge executable not found at {edge_exe}")
