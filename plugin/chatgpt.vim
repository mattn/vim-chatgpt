command -nargs=* ChatGPT call chatgpt#send(<q-args>)
command -nargs=0 CodeReviewPlease call chatgpt#code_review_please()
command -range PleaseGenerateTest '<,'> call chatgpt#generate_test_please()
