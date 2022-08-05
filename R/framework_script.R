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

# set cdm_details

cdm_details <- create_cdm_details(connection_details = connection_details,
                                  cdm_schema = cdm_schema,
                                  vocabulary_schema = vocabulary_schema,
                                  results_schema = results_schema)

#vocab <- connect_to_vocab(cdm_details)
results <- connect_to_vocab(cdm_details)
cdm <- connect_to_cdm(cdm_details)
  
connect_to_cdm <- function(cdm_details) {
  con <- DatabaseConnector::connect(cdm_details@connection_details)
  
  cdm_table_names <- get_cdm_table_names(version = "5.3.0")
  
  
  cdm <- dm::dm_from_con(con = con, 
                  table_names = cdm_tables$table, 
                  schema = cdm_details@cdm_schema)
  
  return(cdm)
}


# create cohorts
cohort_definition <- Capr::createCohortDefinition() %>%
  Capr::addInclusionCriteria() %>%
  Capr::setCohortExit()


cohorts <- list(
  cohort_1 = result_reference_object(type = "cohort"),
  cohort_2 = cohort_reference_object()
)

cohort <- generate(definition = cohort_definition,
                    cdm_details = cdm_details,
                    output_type = cdm_results(table = "ex_cohort", 
                                              cohort_definition_id = 876L),
                    add_inclusion_rule_stats = TRUE)
#output_type = andromeda_result(table = "ex_cohort"), 




covariate_definition <- define_covariates(temporalStartDays = c(0,30, 180),
                                          temporalEndDays = c(29, 31, 91))


covariates <- generate(definition = covariate_definition,
                       cdm_details = cdm_details,
                       cohort_reference = cohorts, 
                       output_type = andromeda_result(),
                       aggregate = aggregate_default()) 



cohort %>%
  collect() #SELECT * FROM results.cohort WHERE cohort_definition_id = 876

covariates %>%
  collect() #SELECT * FROM covariates JOIN covari....

covariates %>%
  collect(table = "covariates") %>%
  select() %>%
  as_dt() #implicit print

covariates %>%
  collect() %>%
  plot_manhattan()#implicit print


cohort_method_definition(
  targetCohortId = 1,
  comparator = 2,
  outcome =3,
  start,
  end,
  firstExposure,
  washoutPeriod
)

cohort_method_data <- generate(definition = cohort_method_definition,
                               cdm_details = cdm_details,
                               cohort_reference = cohorts,
                               covariate_refence = covariates)



model(formula = giBleed ~ c(coxib,diclofenac) + Z,
      data = cohort_method_data,
      family = "binomial",
      optim = "cyclops",
      Z = prop_score(covariates))






