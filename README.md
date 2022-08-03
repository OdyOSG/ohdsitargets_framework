
# Database References

In an OHDSI study we must be able to connect to an OMOP CDM. This is done using the `DatabaseConnector` package, where we set the connection details. The connection details specify the driver, dbms and connection credentials to access the OMOP data. Once a connection has been established the next step is to define three schemas: 1) cdm, 2) vocabulary and 3) results. The cdm schema is where all of the patient level data is contained in the OMOP cdm format. The vocabulary schema contains the concepts and rollups to identify clinical events. Finally, the results schema is a write space that allows us to build a cohort table. This cohort table is populated with the result of queries involving the cdm and vocabularies.

For `ohdsitargets`, it is important to align these three pieces used to generate evidence. The goal is to provide a better interface to work with OMOP CDM from R. Streamlining the interface allows us to garner the benefits of using a targets pipeline, such as not re-executing code that has already been run and running tasks in parallel. The current set-up for OHDSI studies is confusing when it comes to these important pieces. By formally defining them through targets we hope it improves the construction of new studies and methodologies.

## connection_details

The first step in an ohdsi study is to establish a connection to the backend database that hosts the OMOP data. Using the new Database Connector interface this is shown in the code chunk below:

```{r}
#| label: connection_Details

connection_details <- DatabaseConnector::createConnectionDetails(
  drv = RPostgres::Postgres(),
  host     = strsplit(keyring::key_get("cdm_server"), "/")[[1]][[1]],
  dbname   = strsplit(keyring::key_get("cdm_server"), "/")[[1]][[2]],
  user     = keyring::key_get("cdm_user"),
  password = keyring::key_get("cdm_password"),
  port     = "5441"
)
```

## cdm_details

Once the `connection_details` have been defined the next step is to identify the cdm. The function `create_cdm_details` inherits the `connection_details` and provides slots of information about the schema that holds the cdm and vocabulary.

```{r}
#| label: cdm_details
cdm_details <- create_cdm_details(connection_details = connection_details,
                                  cdm_database_schema = cdm_database_schema,
                                  vocabulary_database_schema = vocabulary_database_schema)

```

From the cdm details, we can get information about the tables within these schemas and view the data model representation of the cdm and vocabulary. We will discuss more about views in a separate section

```{r}
#| label: view_cdm
view_cdm(cdm_details)
view_vocabulary(cdm_details)

```

The purpose the `cdm_details` is to orient the functions on which schemas to search for data in the OMOP CDM and provide meta data about the vocabulary version, cdm version, and database name.

Eventually we would like to provide function that report information about data in the cdm, similar to achilles and DQD.

## cohort_reference

When doing an analysis we always have a cohort or a series of cohorts we wish to work with. The `cohort_reference` provides information of where to write or read cohorts on the backend.

```{r}
#| label: cohort_reference
cohort_reference <- create_cohort_reference(
  connection_details = connection_details,
  results_database_schema = results_database_schema,
  project_name = "project_a",
  add_inclusion_tables = TRUE)
```

The `cohort_reference` object contains a slot with the results schema and creates the cohort table. It also time stamps when this table was created. There is an additional option that asks whether to also create inclusion tables in the results schema.

In addition to a create, we may also need a kind of find function. Look up tables in the results schema that match a project_name.

```{r}
find_cohort_reference(connection_details = connection_details,
                      results_database_schema = results_database_schema,
                      prefix = "project_a")
```

The reason for this is if you restart your R session and the `cohort_reference` object is deleted from the global environment, we need to make sure the cohort tables are not rewritten. The issue with just finding is that there is no check to see if any changes have been made to the cohort tables, without tracking the original `cohort_reference` object. Maybe there needs to be another table written to the results schema called cohort_meta that provides a tracker of when the cohorts where instantiated in the cohort table, outside the R session.

# Verbiage

Whether this is defined in ohdsitargets or in another package, we wish to create a clean interface that is profound and robust. Meaning it does a lot of work for the user but is also flexible to several object structures. We have come up with 5 base verbs that fit in the pipeline: 1) `define`, 2) `generate`, 3) `save`/`load`, 4) `view` and 5) `print`.

## `define`

With the function `define` we define the settings used for the object we want to create. For example, if we have a treatment pathways analysis we `define_treatment_pathways` and provide the specific options for the treatment pathways type of analysis. The `define` verb is always separated by the analysis noun using an underscore to differentiate the analysis.

```{r}
#| label: define_tp
treatment_pattern_definition <- define_treatment_patterns(
  target_cohort_id = 10L,
  target_cohort_name = "hypertension",
  event_cohort_ids = 1:6,
  event_cohort_names = c("ace", "arb", "betaBlocker", 
                         "alphaBlocker", "diuretic", "ccb"),
  include_treatments = "startDate",
  period_prior_to_index = 0L,
  min_era_duration = 0L,
  era_collapse_size = 90L,
  min_post_combination_duration = 30L,
  filter_treatments = "Changes",
  max_path_length = 3L,
  min_cell_count = 5L,
  min_cell_method = "Remove",
  group_combinations = 10L,
  add_no_paths = FALSE
  )
```

In the example above we provide the settings for a treatment pathways analysis in the defintion. When we execute the analysis, we use these options in the deployment.

## `generate`

## `save`/`load`

## `view`

## `print`

## Specialty

### *diagnose*

### *aggregate*

### *import*

# Analysis Objects

## Cohort Definition

## Concepts

## Incidence

## Pathways

## Durations

## Covariates

## Strata

## Prevalence

# Output Formats

## andromeda

# Factories

