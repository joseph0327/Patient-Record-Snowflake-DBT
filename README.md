# 🏥 Patient Healthcare Data Platform — dbt + Snowflake

> **An end-to-end healthcare data engineering project using synthetic healthcare data generated through fake APIs and sample files, built with Snowflake and dbt.**

This project demonstrates how healthcare data can be ingested from multiple simulated source systems, transformed through a Medallion Architecture, historically tracked using SCD Type 2, and served as analytics-ready datasets.

**Bronze → Staging → Snapshots → Silver → Gold**

![DBT Architecture](https://github.com/joseph0327/Patient-Record-Snowflake-DBT/blob/7fa839d8bfca5e7c690649ced0d4c3aa335daf9e/Snowflake/dbt.png)
---

## 🏗️ Architecture Overview

```text
                    SOURCE SYSTEMS
                          │
                          ▼
                 ┌─────────────────┐
                 │      BRONZE     │
                 │   Raw Ingestion │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │     STAGING     │
                 │ Technical Clean │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │    SNAPSHOTS    │
                 │    SCD Type 2   │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │     SILVER      │
                 │ Dimensions/Facts│
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │      GOLD       │
                 │    Analytics    │
                 └────────┬────────┘
                          │
                          ▼
                 Dashboards / BI / ML
```

---

# 🗄️ Snowflake Database Architecture

**Database:** `PATIENT_RECORD_DB`

The Snowflake database is organized into separate schemas based on the responsibilities of each layer.

```text
PATIENT_RECORD_DB
│
├── BRONZE
├── STAGING
├── SNAPSHOTS
├── SILVER
└── GOLD
```

### Snowflake Database Screenshot

![Snowflake Database Architecture](https://github.com/joseph0327/Patient-Record-Snowflake-DBT/blob/7fa839d8bfca5e7c690649ced0d4c3aa335daf9e/Snowflake/snowflake.png)

---

# 🥉 Bronze — Raw Ingestion

**Database:** `PATIENT_RECORD_DB`
**Schema:** `BRONZE`

The Bronze layer stores data as close as possible to the original source.

### Tables

* `BRONZE_PATIENT`
* `BRONZE_VISIT`
* `BRONZE_DIAGNOSIS`
* `BRONZE_MEDICATION`
* `BRONZE_LAB_RESULT`
* `BRONZE_BILLING`
* `BRONZE_INSURANCE`

### Purpose

* Store raw source data
* Preserve original records
* Maintain an append-only ingestion layer
* Avoid business transformations
* Support auditing
* Support data replay and recovery
* Maintain source-level lineage

---

# 🥈 Staging — Technical Transformation

**Database:** `PATIENT_RECORD_DB`
**Schema:** `STAGING`

The Staging layer performs technical cleaning and standardization without applying business-specific rules.

### Models

* `STG_PATIENT`
* `STG_VISIT`
* `STG_DIAGNOSIS`
* `STG_MEDICATION`
* `STG_LAB_RESULT`
* `STG_BILLING`
* `STG_INSURANCE`

### Transformations

* Cast data types
* Trim strings
* Standardize values
* Normalize ICD-10 codes
* Standardize units
* Deduplicate records
* Select latest records
* Handle null values

> **Design principle:** Staging performs technical transformations, not business logic.

---

# 📸 Snapshots — Historical Tracking

**Database:** `PATIENT_RECORD_DB`
**Schema:** `SNAPSHOTS`

Snapshots preserve changes to records over time using **SCD Type 2** concepts.

### Snapshots

* `PATIENT_SNAPSHOT`
* `BILLING_SNAPSHOT`
* `INSURANCE_SNAPSHOT`
* `VISIT_SNAPSHOT`
* `MEDICATION_SNAPSHOT`

### Typical Columns

* `DBT_VALID_FROM`
* `DBT_VALID_TO`
* `DBT_UPDATED_AT`

Snapshots allow historical questions such as:

> What did the patient record look like at a particular point in time?

---

# 🥈 Silver — Business Data Warehouse

**Database:** `PATIENT_RECORD_DB`
**Schema:** `SILVER`

The Silver layer contains business-ready **dimensions and facts**.

## Dimensions

* `DIM_PATIENT`
* `DIM_PATIENT_HISTORY`
* `DIM_PATIENT_CURRENT`
* `DIM_DOCTOR`
* `DIM_INSURANCE`
* `DIM_INSURANCE_HISTORY`
* `DIM_INSURANCE_CURRENT`
* `DIM_DATE`
* `DIM_DEPARTMENT`

## Facts

* `FACT_VISIT`
* `FACT_BILLING`
* `FACT_BILLING_HISTORY`
* `FACT_BILLING_CURRENT`
* `FACT_MEDICATION`
* `FACT_MEDICATION_HISTORY`
* `FACT_DIAGNOSIS`
* `FACT_LAB_RESULT`

### Silver Layer Responsibilities

* Apply business rules
* Create surrogate keys
* Establish relationships
* Build reusable dimensions
* Build reusable facts
* Implement dimensional modeling
* Support historical and current-state analysis

---

# ⭐ Star Schema

The Silver layer follows a dimensional/star-schema approach.
Sample below:
```text
                    DIM_PATIENT
                         │
                         │
DIM_DOCTOR ─────── FACT_VISIT ─────── DIM_DATE
                         │
                         │
                  DIM_DEPARTMENT
```

---

# 🥇 Gold — Analytics & Consumption

**Database:** `PATIENT_RECORD_DB`
**Schema:** `GOLD`

The Gold layer contains business-facing datasets optimized for analytics, dashboards, reporting, and machine learning.

### Models

* `PATIENT_360`
* `PATIENT_HEALTH_SUMMARY`
* `REVENUE_ANALYTICS`
* `CLAIM_ANALYTICS`
* `DOCTOR_PERFORMANCE`
* `DEPARTMENT_PERFORMANCE`
* `EXECUTIVE_DASHBOARD`
* `READMISSION_ANALYTICS`
* `PATIENT_RISK_SCORE`
* `MEDICATION_ADHERENCE`
* `LAB_TREND_ANALYTICS`

### Use Cases

* Patient 360
* Patient health analysis
* Revenue analytics
* Claims analytics
* Doctor performance
* Department performance
* Executive reporting
* Readmission analysis
* Patient risk scoring
* Medication adherence
* Laboratory trend analysis

---

# 🔧 dbt Transformation Layer

dbt is used to transform and model the data throughout the warehouse.

### dbt Flow

```text
Source Freshness Checks
          │
          ▼
Staging Models
          │
          ▼
Snapshots — SCD Type 2
          │
          ▼
Silver Dimensions & Facts
          │
          ▼
Gold Analytics Models
          │
          ▼
Data Quality Tests
          │
          ▼
Documentation
```

---


---

# 📁 dbt Project Structure

```text
patient_healthcare_dbt/
│
├── dbt_project.yml
│
├── models/
│   ├── staging/
│   │   ├── patient/
│   │   ├── visit/
│   │   ├── diagnosis/
│   │   ├── medication/
│   │   ├── lab/
│   │   ├── billing/
│   │   └── insurance/
│   │
│   ├── silver/
│   │   ├── dimensions/
│   │   │   ├── dim_patient.sql
│   │   │   ├── dim_doctor.sql
│   │   │   ├── dim_date.sql
│   │   │   ├── dim_department.sql
│   │   │   └── dim_insurance.sql
│   │   │
│   │   └── facts/
│   │       ├── fact_visit.sql
│   │       ├── fact_billing.sql
│   │       ├── fact_medication.sql
│   │       ├── fact_diagnosis.sql
│   │       └── fact_lab_result.sql
│   │
│   └── gold/
│       ├── patient_360.sql
│       ├── patient_health_summary.sql
│       ├── revenue_analytics.sql
│       ├── claim_analytics.sql
│       ├── doctor_performance.sql
│       ├── department_performance.sql
│       ├── executive_dashboard.sql
│       ├── patient_risk_score.sql
│       ├── readmission_analytics.sql
│       ├── medication_adherence.sql
│       └── lab_trend_analytics.sql
│
├── snapshots/
│   ├── patient_snapshot.sql
│   ├── billing_snapshot.sql
│   ├── insurance_snapshot.sql
│   ├── visit_snapshot.sql
│   └── medication_snapshot.sql
│
├── macros/
├── tests/
├── seeds/
└── docs/
```

---

# 🔐 Security & Data Governance

Because this project models healthcare data, security and governance are important architectural considerations.

Potential Snowflake controls include:

* Role-Based Access Control (RBAC)
* Masking Policies
* Row Access Policies



---

# 🧪 Data Quality

The project incorporates data-quality practices such as:

### Source Freshness

Ensure source data arrives within the expected timeframe.

### Not Null

Required fields should contain valid values.

### Uniqueness

Business keys should not contain unexpected duplicates.

### Referential Integrity

Fact records should correctly reference dimension records.

```text
FACT_VISIT.PATIENT_KEY
        │
        ▼
DIM_PATIENT.PATIENT_KEY
```


---

# 🔄 End-to-End Pipeline

```text
                    SOURCE DATA
                        │
                        ▼
              ┌──────────────────┐
              │      BRONZE      │
              │   Raw / Audit    │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │     STAGING      │
              │ Technical Clean  │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │    SNAPSHOTS     │
              │    SCD Type 2    │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │      SILVER      │
              │ Dimensions/Facts │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │       GOLD       │
              │ Analytics Models │
              └────────┬─────────┘
                       │
              ┌────────┼────────┐
              ▼        ▼        ▼
          Dashboards Reporting  ML
```

---

# 🛠️ Technology Stack

| Technology             | Purpose                          |
| ---------------------- | -------------------------------- |
| **Snowflake**          | Cloud data warehouse             |
| **dbt**                | Data transformation and modeling |
| **SQL**                | Data transformation              |
| **Git/GitHub**         | Version control                  |
| **Snowflake RBAC**     | Access control                   |
| **Snowflake Policies** | Data governance and security     |

---

# 🎯 Project Goals

This project demonstrates how to build a scalable healthcare analytics platform using modern data-engineering practices.

### Key Concepts

* Medallion architecture
* Snowflake data warehousing
* dbt transformations
* Staging models
* SCD Type 2 snapshots
* Dimensional modeling
* Star schemas
* Fact and dimension tables
* Surrogate keys
* Data quality testing
* Source freshness
* Data governance
* RBAC and security policies
* Analytics-ready data marts
* Healthcare analytics use cases

---


---

# 📌 Project Status

This project is being developed as an end-to-end healthcare data-engineering portfolio project using Snowflake and dbt.

```text
Bronze       → Raw ingestion          ✅
Staging      → Technical cleaning     ✅
Snapshots    → Historical tracking    ✅
Silver       → Warehouse modeling     ✅
Gold         → Analytics              ✅
Testing      → Data quality           ✅
Documentation → dbt docs              🚧
```

---

## 👨‍💻 Architecture Summary

```text
BRONZE
Preserve raw data
      │
      ▼
STAGING
Clean and standardize
      │
      ▼
SNAPSHOTS
Track historical changes
      │
      ▼
SILVER
Build business entities
      │
      ▼
GOLD
Deliver analytics
      │
      ▼
BI / Reporting / ML
```

**Core objective:** Build a trusted healthcare data platform that transforms raw source data into **historical, governed, reusable, and analytics-ready datasets**.
