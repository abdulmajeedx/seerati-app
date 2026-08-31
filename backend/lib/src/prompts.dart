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
