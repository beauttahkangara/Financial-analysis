# Financial-analysis

# Kenyan Tax Data Generator

A Ruby on Rails application that generates and analyzes dummy financial data compliant with KRA requirements.

## Features

- Generates realistic sales, purchases, payroll, and asset data
- Applies correct Kenyan tax rates (VAT, PAYE, WHT, etc.)
- Creates consistent datasets for testing tax analysis systems

## Usage

1. Clone the repository
2. Install dependencies: `bundle install`
3. Generate data: `rake kra:generate`
4. Find output in `lib/assets/kra_data/`

## Requirements

- Ruby 3.0+
- Rails 7.0+
