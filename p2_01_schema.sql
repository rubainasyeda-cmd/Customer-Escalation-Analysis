CREATE DATABASE IF NOT EXISTS customer_ops_registry;
USE customer_ops_registry;

DROP TABLE IF EXISTS quality_audits;
DROP TABLE IF EXISTS interactions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    region VARCHAR(50) NOT NULL,
    account_type VARCHAR(20) CHECK (account_type IN ('Residential', 'Commercial')),
    signup_date DATE NOT NULL
);

CREATE TABLE agents (
    agent_id VARCHAR(20) PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    team VARCHAR(50) CHECK (team IN ('Prepaid', 'Postpaid', 'Billing', 'Meter Services')),
    join_date DATE NOT NULL
);

CREATE TABLE appointments (
    appointment_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    agent_id VARCHAR(20),
    appointment_type VARCHAR(50) CHECK (appointment_type IN ('Meter Fault', 'Billing Correction', 'Installation', 'Inspection')),
    scheduled_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Completed', 'Failed', 'Rescheduled', 'Cancelled')),
    failure_reason VARCHAR(150),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id) ON DELETE CASCADE
);

CREATE TABLE interactions (
    interaction_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    agent_id VARCHAR(20),
    channel VARCHAR(20) CHECK (channel IN ('Email', 'Call', 'Chat')),
    interaction_date DATE NOT NULL,
    issue_type VARCHAR(100) NOT NULL,
    first_contact_resolution VARCHAR(3) CHECK (first_contact_resolution IN ('Yes', 'No')),
    escalated VARCHAR(3) CHECK (escalated IN ('Yes', 'No')),
    escalation_reason VARCHAR(150),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id) ON DELETE CASCADE
);

CREATE TABLE quality_audits (
    audit_id VARCHAR(20) PRIMARY KEY,
    interaction_id VARCHAR(20),
    audit_date DATE NOT NULL,
    csat_score INT CHECK (csat_score BETWEEN 1 AND 5),
    issue_found VARCHAR(150),
    feedback_given VARCHAR(255),
    FOREIGN KEY (interaction_id) REFERENCES interactions(interaction_id) ON DELETE CASCADE
);
