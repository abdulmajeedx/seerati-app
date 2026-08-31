String _lang(String language) => language == 'ar' ? 'Arabic' : 'English';

const _shared = 'You write professional resume content. '
    'Output ONLY the requested text — no preamble, no explanations, no markdown '
    'headers, no quotes around the output. Keep it truthful to the provided '
    'facts; never invent employers, dates, degrees, or metrics.';

String summarySystem(String language) =>
    '$_shared Write in ${_lang(language)}. Produce a resume professional '
    'summary of 2–4 sentences, first person implied (no "I am ..." openings), '
    'confident but not exaggerated.';

String summaryPrompt({
  required String jobTitle,
  required List<String> skills,
  required String currentSummary,
}) =>
    'Job title: $jobTitle\n'
    'Key skills: ${skills.join(', ')}\n'
    '${currentSummary.isEmpty ? '' : 'Current draft to improve: $currentSummary\n'}'
    'Write the professional summary.';

String experienceSystem(String language) =>
    '$_shared Write in ${_lang(language)}. Rewrite the given job description '
    'as 3–5 resume bullet points. Start each with a strong action verb, one '
    'line each, "- " prefix. Quantify only with numbers already provided.';

String experiencePrompt({
  required String jobTitle,
  required String company,
  required String rawDescription,
}) =>
    'Role: $jobTitle at $company\n'
    'What they did, in their own words: $rawDescription\n'
    'Write the bullet points.';

const jobsSystem =
    'You find REAL, currently posted job openings using web search. Run 3–5 '
    'searches (mix Arabic and English queries, include local job boards), then '
    'output ONLY a JSON array — no prose, no markdown fence — of up to 8 '
    'objects with keys: title, company, location, url, why_match. '
    '"why_match" is one short sentence in the requested language explaining the '
    'fit with the candidate. Use ONLY urls that appeared in search results; '
    'never invent or guess a url. Output [] if nothing real was found.';

String jobsPrompt({
  required String language,
  required String jobTitle,
  required String city,
  required bool remote,
  required List<String> skills,
  required String summary,
}) =>
    'Answer "why_match" in ${_lang(language)}.\n'
    'Wanted role: $jobTitle\n'
    '${city.isEmpty ? '' : 'Location: $city\n'}'
    '${remote ? 'Remote work is acceptable.\n' : ''}'
    '${skills.isEmpty ? '' : 'Candidate skills: ${skills.join(', ')}\n'}'
    '${summary.isEmpty ? '' : 'Candidate background: $summary\n'}'
    'Find matching openings.';

String coverLetterSystem(String language) =>
    '$_shared Write in ${_lang(language)}. Produce a complete cover letter '
    'body (greeting through sign-off) of 150–250 words, tailored to the job '
    'ad. Professional, specific, no clichés like "team player".';

String coverLetterPrompt({
  required String applicantName,
  required String jobTitle,
  required String company,
  required String jobAd,
  required String resumeSummary,
}) =>
    'Applicant: $applicantName\n'
    '${jobTitle.isEmpty ? '' : 'Position: $jobTitle\n'}'
    '${company.isEmpty ? '' : 'Company: $company\n'}'
    '${resumeSummary.isEmpty ? '' : 'Applicant background: $resumeSummary\n'}'
    'Job ad:\n$jobAd\n'
    'Write the cover letter.';
