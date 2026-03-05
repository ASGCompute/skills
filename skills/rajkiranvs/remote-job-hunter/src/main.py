#!/usr/bin/env python3
"""
main.py — Entry point for remote-job-hunter skill.
Usage:
  python3 src/main.py --profile-config path/to/profile.json \
                      --profile-meta profiles/ai-ml.json \
                      --output daily_report.md
"""
import json, argparse, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from search import fetch_all
from scorer import score_jobs
from gaps import analyze_gaps
from report import generate_report

def main():
    parser = argparse.ArgumentParser(description="remote-job-hunter — AI-powered remote job search")
    parser.add_argument("--profile-config", required=True, help="Path to user profile JSON")
    parser.add_argument("--profile-meta", required=True, help="Path to domain profile JSON (e.g. profiles/ai-ml.json)")
    parser.add_argument("--output", default="daily_report.md", help="Output report path")
    args = parser.parse_args()

    # Load configs
    with open(args.profile_config) as f:
        profile_config = json.load(f)
    with open(args.profile_meta) as f:
        profile_meta = json.load(f)

    domain = profile_meta["domain"]
    phrases = profile_meta["phrases"]
    resume_path = Path(profile_config["resume_path"]).expanduser()
    salary_min = profile_config.get("salary_min_usd", 0)
    salary_filter = profile_meta.get("salary_filter_enabled", False)

    print(f"\n🔍 remote-job-hunter v1.0.0")
    print(f"Profile: {profile_meta['label']} ({profile_config['name']})")
    print(f"Domain: {domain} | Salary: {'${:,}+'.format(salary_min) if salary_filter else 'All'}\n")

    # Fetch
    print("Fetching jobs...")
    jobs = fetch_all(domain, phrases, profile_config)

    # Score
    print("\nScoring jobs against resume...")
    scored_jobs, known_skills = score_jobs(jobs, domain, str(resume_path))

    # Apply salary filter
    if salary_filter and salary_min:
        def salary_ok(job):
            sal = job.get("salary", "")
            if sal == "Not listed":
                return True  # Keep — negotiate
            try:
                num = int(''.join(filter(str.isdigit, sal.split("K")[0].replace("$", ""))))
                return num * 1000 >= salary_min
            except:
                return True
        scored_jobs = [j for j in scored_jobs if salary_ok(j)]

    # Analyze gaps
    print("\nAnalyzing skill gaps...")
    gap_analysis = analyze_gaps(scored_jobs, known_skills)
    gap_analysis["known_skills"] = known_skills

    # Generate report
    print("\nGenerating report...")
    generate_report(scored_jobs, gap_analysis, profile_config, profile_meta, args.output)

    # Print summary
    green = [j for j in scored_jobs if j.get("match_score") and j["match_score"] >= 80]
    print(f"\n📊 Summary:")
    print(f"   Total jobs: {len(scored_jobs)}")
    print(f"   🟢 80%+ match: {len(green)}")
    if gap_analysis["top_missing"]:
        print(f"\n⚠️  Top skill gaps:")
        for skill, count in gap_analysis["top_missing"][:5]:
            print(f"   - {skill.title()} ({count} jobs)")

if __name__ == "__main__":
    main()
