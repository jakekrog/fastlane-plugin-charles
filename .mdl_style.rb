all
exclude_rule 'MD013' # line length — not practical given long link/badge lines in these docs
rule 'MD029', style: :ordered # this project numbers lists sequentially (1, 2, 3), not all "1."
# GitHub's PR/issue templates intentionally start with a non-H1 heading,
# since the PR/issue title itself serves that role.
exclude_rule 'MD002' # first header should be a top level header
exclude_rule 'MD041' # first line in file should be a top level header
