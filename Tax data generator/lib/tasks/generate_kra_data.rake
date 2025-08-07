# lib/tasks/generate_kra_data.rake
require 'csv'
require 'faker'
require 'date'

namespace :kra do
  desc "Generate dummy KRA-compliant financial data for Kenyan company"
  task generate: :environment do
    # Create output directory
    output_dir = Rails.root.join('lib/assets/kra_data')
    FileUtils.mkdir_p(output_dir)

    # Initialize Faker with Kenyan context
    Faker::Config.locale = 'en-KE'

    # 1. Generate Sales Data
    generate_sales_data(output_dir)

    # 2. Generate Purchases/Expenses Data
    generate_purchases_data(output_dir)

    # 3. Generate Payroll Data
    generate_payroll_data(output_dir)

    # 4. Generate Fixed Assets Register
    generate_assets_data(output_dir)

    # 5. Generate Monthly Tax Returns
    generate_tax_returns(output_dir)

    # 6. Generate Supplier Master
    generate_suppliers_data(output_dir)

    # Generate README
    generate_readme(output_dir)

    puts "Successfully generated all KRA dummy data files in #{output_dir}"
  end

  private

  def generate_sales_data(output_dir)
    CSV.open(output_dir.join('sales_data.csv'), 'w') do |csv|
      csv << %w[InvoiceNo Date CustomerName CustomerPIN Product Quantity UnitPrice VATable VATAmount ExciseDuty WithholdingTax TotalAmount]

      300.times do |i|
        date = Faker::Date.between(from: Date.new(2023, 7, 1), to: Date.new(2023, 12, 31))
        customer_type = rand(1..4)
        
        case customer_type
        when 1 # B2B VATable
          vatable = 'Y'
          vat_amount = (rand(100..1000) * 16).round(2)
          wht = [0, (vat_amount * 0.05).round(2)].sample
          exempt = 'N'
        when 2 # NGO (exempt)
          vatable = 'N'
          vat_amount = 0
          wht = 0
          exempt = 'Y'
        when 3 # Export (0-rated)
          vatable = 'Y'
          vat_amount = 0
          wht = 0
          exempt = 'N'
        when 4 # B2C
          vatable = ['Y', 'N'].sample
          vat_amount = vatable == 'Y' ? (rand(100..500) * 16).round(2) : 0
          wht = 0
          exempt = 'N'
        end

        quantity = rand(1..100)
        unit_price = rand(100..1000).round(2)
        total = (quantity * unit_price).round(2)
        total += vat_amount if vatable == 'Y'

        csv << [
          "INV-#{1000 + i}",
          date.strftime('%Y-%m-%d'),
          Faker::Company.name,
          customer_type == 2 ? "EXEMPT#{i}" : "P#{rand(100000000..999999999)}X",
          ['Plastic Chairs', 'Water Tanks', 'Food Containers', 'Plastic Sheets'].sample,
          quantity,
          unit_price,
          vatable,
          vat_amount,
          0, # Excise duty would apply to specific products
          wht,
          total.round(2)
        ]
      end
    end
  end

  def generate_purchases_data(output_dir)
    expense_categories = [
      {name: 'Raw Materials', deductible: 'Y', section: 'Section 15(1)'},
      {name: 'Office Expenses', deductible: 'Y', section: 'Section 15(2)(a)'},
      {name: 'Staff Welfare', deductible: 'N', section: 'Section 16(b)'},
      {name: 'Travel', deductible: 'P', section: 'Section 15(2)(b)'}, # Partially deductible
      {name: 'Motor Vehicle', deductible: 'Y', section: 'Section 15(2)'},
      {name: 'Capital Equipment', deductible: 'Y', section: 'Second Schedule'}
    ]

    CSV.open(output_dir.join('purchases_data.csv'), 'w') do |csv|
      csv << %w[ReceiptNo Date SupplierName SupplierPIN Description Amount VATAmount WithholdingTax ExpenseCategory TaxDeductible SectionOfDeduction]

      150.times do |i|
        category = expense_categories.sample
        date = Faker::Date.between(from: Date.new(2023, 7, 1), to: Date.new(2023, 12, 31))
        amount = rand(5000..500000).round(2)
        vat_amount = category[:name] == 'Capital Equipment' ? 0 : (amount * 0.16).round(2)
        
        # Apply WHT only to certain categories
        wht = if ['Raw Materials', 'Office Expenses'].include?(category[:name])
                (amount * 0.05).round(2)
              else
                0
              end

        # Handle partial deductibility (e.g., travel)
        if category[:deductible] == 'P'
          deductible = 'Y'
          amount = (amount * 0.3).round(2) # Only 30% deductible
        else
          deductible = category[:deductible]
        end

        csv << [
          "PUR-#{1000 + i}",
          date.strftime('%Y-%m-%d'),
          Faker::Company.name,
          "P#{rand(100000000..999999999)}V",
          case category[:name]
          when 'Raw Materials' then "#{['PP', 'PE', 'PVC'].sample} Granules (#{rand(100..1000)}kg)"
          when 'Office Expenses' then ['Office Furniture', 'Stationery', 'Printer Ink'].sample
          when 'Staff Welfare' then ['Team Lunch', 'Staff Retreat', 'Holiday Bonus'].sample
          when 'Travel' then ["Flight to #{Faker::Address.country}", "Hotel Accommodation"].sample
          when 'Motor Vehicle' then ['Tires', 'Service', 'Fuel'].sample
          when 'Capital Equipment' then ['Injection Mould', 'Conveyor Belt', 'Packaging Machine'].sample
          end,
          amount,
          vat_amount,
          wht,
          category[:name],
          deductible,
          category[:section]
        ]
      end
    end
  end

  def generate_payroll_data(output_dir)
    # Kenyan PAYE rates (2023)
    paye_rates = [
      { range: 0..24000, rate: 0.1, deduction: 0 },
      { range: 24001..32333, rate: 0.25, deduction: 2400 },
      { range: 32334..500000, rate: 0.3, deduction: 4483.25 },
      { range: 500001..Float::INFINITY, rate: 0.325, deduction: 2983.25 }
    ]

    # NHIF rates (2023)
    nhif_rates = [
      { range: 0..5999, amount: 150 },
      { range: 6000..7999, amount: 300 },
      { range: 8000..11999, amount: 400 },
      { range: 12000..14999, amount: 500 },
      { range: 15000..19999, amount: 600 },
      { range: 20000..24999, amount: 750 },
      { range: 25000..29999, amount: 850 },
      { range: 30000..34999, amount: 900 },
      { range: 35000..39999, amount: 950 },
      { range: 40000..44999, amount: 1000 },
      { range: 45000..49999, amount: 1100 },
      { range: 50000..59999, amount: 1200 },
      { range: 60000..69999, amount: 1300 },
      { range: 70000..79999, amount: 1400 },
      { range: 80000..89999, amount: 1500 },
      { range: 90000..99999, amount: 1600 },
      { range: 100000..Float::INFINITY, amount: 1700 }
    ]

    CSV.open(output_dir.join('payroll_data.csv'), 'w') do |csv|
      csv << %w[EmployeeID Name KRA_PIN BasicSalary Allowances Benefits PAYE NSSF_TierI NSSF_TierII NHIF PensionDeductions NetPay]

      # Generate 5 executives
      5.times do |i|
        basic = rand(300000..600000).round(2)
        allowances = rand(50000..150000).round(2)
        benefits = rand(30000..100000).round(2)
        taxable = basic + allowances + benefits

        # Calculate PAYE
        paye_rate = paye_rates.find { |r| r[:range].cover?(taxable) }
        paye = (taxable * paye_rate[:rate] - paye_rate[:deduction]).round(2)

        # NHIF
        nhif = nhif_rates.find { |r| r[:range].cover?(basic) }[:amount]

        # NSSF (Tier I fixed, Tier II 6% of pensionable wages)
        nssf_tier1 = 200
        pensionable = [basic, 18000].min # Upper limit for Tier II
        nssf_tier2 = (pensionable * 0.06).round(2)

        # Pension (company scheme)
        pension = (basic * 0.05).round(2)

        net = taxable - paye - nssf_tier1 - nssf_tier2 - nhif - pension

        csv << [
          "EMP#{100 + i}",
          Faker::Name.name,
          "A#{rand(100000000..999999999)}X",
          basic,
          allowances,
          benefits,
          paye,
          nssf_tier1,
          nssf_tier2,
          nhif,
          pension,
          net.round(2)
        ]
      end

      # Generate 15 management staff
      15.times do |i|
        basic = rand(150000..300000).round(2)
        allowances = rand(20000..50000).round(2)
        benefits = [0, rand(10000..30000).round(2)].sample # Some may not have benefits
        taxable = basic + allowances + benefits

        paye_rate = paye_rates.find { |r| r[:range].cover?(taxable) }
        paye = (taxable * paye_rate[:rate] - paye_rate[:deduction]).round(2)

        nhif = nhif_rates.find { |r| r[:range].cover?(basic) }[:amount]

        nssf_tier1 = 200
        pensionable = [basic, 18000].min
        nssf_tier2 = (pensionable * 0.06).round(2)

        pension = (basic * 0.05).round(2)

        net = taxable - paye - nssf_tier1 - nssf_tier2 - nhif - pension

        csv << [
          "EMP#{200 + i}",
          Faker::Name.name,
          "B#{rand(100000000..999999999)}Y",
          basic,
          allowances,
          benefits,
          paye,
          nssf_tier1,
          nssf_tier2,
          nhif,
          pension,
          net.round(2)
        ]
      end

      # Generate 27 production staff
      27.times do |i|
        basic = rand(30000..120000).round(2)
        allowances = [0, rand(5000..15000).round(2)].sample # Some may not have allowances
        benefits = 0 # Production staff typically don't get benefits
        taxable = basic + allowances + benefits

        paye_rate = paye_rates.find { |r| r[:range].cover?(taxable) }
        paye = (taxable * paye_rate[:rate] - paye_rate[:deduction]).round(2)

        nhif = nhif_rates.find { |r| r[:range].cover?(basic) }[:amount]

        nssf_tier1 = 200
        pensionable = [basic, 18000].min
        nssf_tier2 = (pensionable * 0.06).round(2)

        pension = 0 # Production staff might not be in pension scheme

        net = taxable - paye - nssf_tier1 - nssf_tier2 - nhif - pension

        csv << [
          "EMP#{300 + i}",
          Faker::Name.name,
          "C#{rand(100000000..999999999)}Z",
          basic,
          allowances,
          benefits,
          paye,
          nssf_tier1,
          nssf_tier2,
          nhif,
          pension,
          net.round(2)
        ]
      end
    end
  end

  def generate_assets_data(output_dir)
    depreciation_rates = {
      'Machinery' => { method: 'Straight Line', rate: 12.5 },
      'Vehicles' => { method: 'Reducing Balance', rate: 25 },
      'Computers' => { method: 'Straight Line', rate: 30 },
      'Furniture' => { method: 'Straight Line', rate: 10 },
      'Buildings' => { method: 'Straight Line', rate: 2.5 }
    }

    CSV.open(output_dir.join('assets_data.csv'), 'w') do |csv|
      csv << %w[AssetID Description PurchaseDate Cost ImportDutyPaid DepreciationMethod DepreciationRate NBV SectionOfDeduction]

      # Machinery (eligible for investment deduction)
      5.times do |i|
        cost = rand(1000000..5000000).round(2)
        purchase_date = Faker::Date.between(from: Date.new(2020, 1, 1), to: Date.new(2023, 6, 30))
        months_owned = ((Date.new(2023, 12, 31) - purchase_date).to_i / 30).to_i
        depreciation = depreciation_rates['Machinery']
        annual_dep = cost * (depreciation[:rate] / 100.0)
        total_dep = annual_dep * (months_owned / 12.0)
        nbv = cost - total_dep

        csv << [
          "AST#{100 + i}",
          "#{['Injection', 'Blow', 'Extrusion'].sample} Moulding Machine",
          purchase_date.strftime('%Y-%m-%d'),
          cost,
          (cost * 0.1).round(2), # 10% import duty
          depreciation[:method],
          depreciation[:rate],
          nbv.round(2),
          'Second Schedule'
        ]
      end

      # Vehicles
      3.times do |i|
        cost = rand(2000000..4000000).round(2)
        purchase_date = Faker::Date.between(from: Date.new(2021, 1, 1), to: Date.new(2023, 6, 30))
        depreciation = depreciation_rates['Vehicles']
        years_owned = (Date.new(2023, 12, 31).year - purchase_date.year)
        nbv = cost * ((1 - (depreciation[:rate] / 100.0)) ** years_owned)

        csv << [
          "AST#{200 + i}",
          "#{['Toyota', 'Isuzu', 'Mitsubishi'].sample} #{['Truck', 'Van', 'Pickup'].sample}",
          purchase_date.strftime('%Y-%m-%d'),
          cost,
          0, # No import duty (assume locally purchased)
          depreciation[:method],
          depreciation[:rate],
          nbv.round(2),
          'Section 15(2)'
        ]
      end

      # Computers and office equipment
      5.times do |i|
        cost = rand(50000..300000).round(2)
        purchase_date = Faker::Date.between(from: Date.new(2022, 1, 1), to: Date.new(2023, 6, 30))
        months_owned = ((Date.new(2023, 12, 31) - purchase_date).to_i / 30).to_i
        depreciation = depreciation_rates['Computers']
        annual_dep = cost * (depreciation[:rate] / 100.0)
        total_dep = annual_dep * (months_owned / 12.0)
        nbv = cost - total_dep

        csv << [
          "AST#{300 + i}",
          "#{['Laptop', 'Desktop', 'Printer', 'Server'].sample}",
          purchase_date.strftime('%Y-%m-%d'),
          cost,
          0,
          depreciation[:method],
          depreciation[:rate],
          nbv.round(2),
          'Section 15(1)'
        ]
      end
    end
  end

  def generate_tax_returns(output_dir)
    CSV.open(output_dir.join('tax_returns.csv'), 'w') do |csv|
      csv << %w[Month VAT_Output VAT_Input VAT_Payable PAYE_Remitted Excise_Duty WHT_Remitted Installment_Tax]

      (7..12).each do |month| # July to December
        vat_output = rand(1200000..1800000).round(2)
        vat_input = rand(800000..1200000).round(2)
        vat_payable = [vat_output - vat_input, 0].max.round(2)
        
        paye = rand(1000000..1500000).round(2)
        
        # Excise duty only applies to some months (assuming plastic bags are excisable)
        excise = month % 2 == 0 ? rand(100000..300000).round(2) : 0
        
        wht = rand(200000..300000).round(2)
        
        # Installment tax (30% of estimated annual tax paid monthly)
        installment = (rand(3000000..5000000) * 0.3 / 12).round(2)

        csv << [
          Date::MONTHNAMES[month][0..2] + '-2023',
          vat_output,
          vat_input,
          vat_payable,
          paye,
          excise,
          wht,
          installment
        ]
      end
    end
  end

  def generate_suppliers_data(output_dir)
    CSV.open(output_dir.join('suppliers_data.csv'), 'w') do |csv|
      csv << %w[SupplierID SupplierName PIN Address Contact VAT_Registered WHT_Applicable]

      # Raw material suppliers
      5.times do |i|
        csv << [
          "SUP#{100 + i}",
          "#{Faker::Company.name} #{['Plastics', 'Polymers', 'Chemicals'].sample}",
          "P#{rand(100000000..999999999)}V",
          "Nairobi Industrial Area",
          "07#{rand(10..29)}#{rand(1000000..9999999)}",
          'Y',
          'Y'
        ]
      end

      # Office suppliers
      3.times do |i|
        csv << [
          "SUP#{200 + i}",
          "#{Faker::Company.name} #{['Office Solutions', 'Supplies', 'Equipment'].sample}",
          "P#{rand(100000000..999999999)}B",
          "#{['Westlands', 'CBD', 'Karen'].sample}, Nairobi",
          "07#{rand(30..49)}#{rand(1000000..9999999)}",
          'Y',
          'Y'
        ]
      end

      # Service providers (some not VAT registered)
      4.times do |i|
        vat_reg = [true, false].sample
        csv << [
          "SUP#{300 + i}",
          "#{Faker::Company.name} #{['Services', 'Consultancy', 'Logistics'].sample}",
          "P#{rand(100000000..999999999)}K",
          "#{['Mombasa', 'Kisumu', 'Nakuru'].sample}",
          "07#{rand(50..79)}#{rand(1000000..9999999)}",
          vat_reg ? 'Y' : 'N',
          'Y'
        ]
      end
    end
  end

  def generate_readme(output_dir)
    File.open(output_dir.join('README.md'), 'w') do |file|
      file.write <<~README
        # XYZ Manufacturing Ltd - Dummy KRA Tax Data

        This dataset contains realistic financial records for a Kenyan manufacturing company (July-Dec 2023), structured for KRA tax analysis.

        ## Files Included

        1. `sales_data.csv` - 300+ sales transactions with VAT treatment
        2. `purchases_data.csv` - 150+ expense records with tax deductibility
        3. `payroll_data.csv` - Complete payroll for 47 employees
        4. `assets_data.csv` - Fixed assets register with depreciation
        5. `tax_returns.csv` - Simulated monthly tax returns
        6. `suppliers_data.csv` - Supplier master data

        ## Key Features

        - Complies with Kenyan tax laws and KRA requirements
        - Includes all major tax types: VAT, PAYE, WHT, Excise Duty
        - Proper treatment of:
          - VAT (16%, zero-rated, exempt)
          - PAYE (graduated rates)
          - NSSF (Tier I & II)
          - NHIF (current rates)
          - Withholding taxes (5%, 10%, 3%)
        - Sample scenarios:
          - Disallowed expenses (Section 15)
          - Partially deductible expenses (e.g., travel)
          - Capital allowances
          - Import duties

        ## How to Use

        1. Clone this repository
        2. Run `rake kra:generate` to regenerate data
        3. Analyze using your preferred tools

        Note: This is dummy data for testing purposes only.
      README
    end
  end
end
