# Idea for ohdsitargets framework

# setup ---------------------

# define connection details
# Using new DatabaseConnector interface
connection_details <- DatabaseConnector::createConnectionDetails(
  RPostgres::Postgres(),
  host     = strsplit(keyring::key_get("cdm_server"), "/")[[1]][[1]],
  dbname   = strsplit(keyring::key_get("cdm_server"), "/")[[1]][[2]],
  user     = keyring::key_get("cdm_user"),
  password = keyring::key_get("cdm_password"),
  port     = "5441"
)

# set cdm_reference
# set implies a side effect (e.g. get/set pair for setting attributes of an object)
# Here we are just creating a cdm details object
# We probably should choose either camel or snake case or support both styles but stick to one style within a project.


# This is an object that describes how to access a CDM later in proram execution
cdm_details <- create_cdm_details(connection_details = connection_details,
                                cdm_database_schema = cdm_database_schema,
                                vocabulary_database_schema = vocabulary_database_schema)


con <- connect(connection_details)
# this is a live reference to the cdm tables
cdm <- dm::dm_from_src(src = con, tables = cdm_tables)


# set results_reference
#same idea as this:
# cohortTableRef <- ohdsitargets::create_cohort_tables(name = studyName,
#                                                      connectionDetails = connectionDetails,
#                                                      cohortDatabaseSchema = resultsDatabaseSchema)
#this is a more flexible version that can create andromeda
#essentially this defining the standard out:
#either write to the db, write to andromeda, or write to a file

# results are going to be rectangular tables which can be in the database, or in andromeda

results_reference <- set_results_reference(type = c("db", "andromeda", "flat"),
                                           results_schema = results_schema,
                                           andromeda_path,
                                           flat_file_path,
                                           project_name = "project_name")

# I'm not sure about this. We definitely need a way to tell generate where to put the results.
# I think the generate function should return a results_reference but not necesarily take a results reference as input.




# definitions ----------------
# ways to define cohort definitions
# plural makes it a set
# input can be json or capr
cohort_definition <- define_cohort_json(name = "cohort",
                                        path_to_json)
cohort_definitions <- define_cohorts_json(names,
                                          json_directory)
cohort_definition <- define_cohort_capr(name = "cohort",
                                        capr_obj)
cohort_definitions <- define_cohorts_capr(names,
                                          list(cap_objs))

# The define function for a cohort would be something like this
cohort_definition <- Capr::createCohortDefinition() %>%
  Capr::addInclusionCriteria() %>%
  Capr::setCohortExit()

# for a json file the define function would be something like
cohort_definition <- Capr::readInCirce(jsonPath) # this is basically the "load" function for circe json


# define covariates

covariate_definition <- define_covariates("<FeatureExtraction_inputs>")

#define treatment patterns

treatment_pattern_definition <- define_treatment_patterns("<TreatmentPatterns_inputs>")

# define strata

strata_definition <- define_strata(type = "concept", ...)

# generations -------------------------

#generic

# output tells generate where to put the data
generated_object <- generate(definition,
                             cdm,
                             output = db("tableName")) # could also be andromeda("tableName") or a file path

# We need something similar to "tidy select" for specifying output formats

# generate always returns a "results reference" object that could point to a database table or andromeda object.
# We might want to use duckdb here too.

generated_cohort <- generate(cohort_defintion,
                             list(cdm_reference),
                             list(results_reference))

generated_treatment_pattern <- generate(treatment_pattern_definition,
                                        input = list(cdm_reference, cohort_reference),
                                        output = list(results_reference))

generated_covariates <- generate(covariate_definition,
                                 input = list(cdm_reference, cohort_reference),
                                 output = list(results_reference))
# save/load -----------------------
#these can be nested within generate if an output is specified
save(generated_object,
     output = results_reference)

load(input = path, output = "cohort") #output meaning object format

# might also consider "read/write" pairing and how they are different from save/load. (e.g. read_csv, write_csv)


# view -----------------------

# Might consider the as.table() generic
sloop::is_s3_generic("as.table") # TRUE

# View implies a side effect of printing or opening a viewer.

view_table(generated_cohort, output = "DT")
view_table(generated_cohort, output = "kable")

view_table(generated_covariates, output = "DT")


view_manhattan(generated_covariates, output = manhattan_options(...))
