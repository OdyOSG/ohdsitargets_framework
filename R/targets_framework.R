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

cdm_reference <- set_cdm_reference(connection_details = connection_details,
                                   cdm_database_schema = cdm_database_schema,
                                   vocabulary_database_schema = vocabulary_database_schema,
                                   results_database_schema = results_database_schema)


cdm <- dm::dm_from_con(con = con, table_names = cdm_tables$table, learn_keys = FALSE, schema = "cdm_531")

# set results_reference
#same idea as this:
# cohortTableRef <- ohdsitargets::create_cohort_tables(name = studyName,
#                                                      connectionDetails = connectionDetails,
#                                                      cohortDatabaseSchema = resultsDatabaseSchema)
#this is a more flexible version that can create andromeda 
#essentially this defining the standard out:
#either write to the db, write to andromeda, or write to a file

results_reference <- set_results_reference(type = c("db", "andromeda", "tibble"),
                                           path,
                                           project_name = "project_name")


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

# define covariates

covariate_definition <- define_covariates("<FeatureExtraction_inputs>")

#define treatment patterns

treatment_pattern_definition <- define_treatment_patterns("<TreatmentPatterns_inputs>")

# define strata

strata_definition <- define_strata(type = "concept", ...)

# generations -------------------------

#generic
generated_object <- generate(definition,
                             input,
                             output)

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


# view -----------------------

view_table(generated_cohort, output = "DT")
view_table(generated_cohort, output = "kable")

view_table(generated_covariates, output = "DT")


view_manhattan(generated_covariates, output = manhattan_options(...))
