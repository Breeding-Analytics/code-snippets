# specify the URL to a file hosted online
geno_url <- "https://raw.githubusercontent.com/Breeding-Analytics/bioflow/main/inst/app/www/example/pheno.csv"

# create a temporary file in the system's temporary directory with the correct extension
temp_file <- tempfile(tmpdir = tempdir(), fileext = sub(".*\\.([a-zA-Z0-9]+)$", ".\\1", geno_url))

# download the file from the URL and saves it in the temporary location
utils::download.file(geno_url, temp_file)

# reads the downloaded file into an R in a regular way
df <- read.csv(temp_file)
