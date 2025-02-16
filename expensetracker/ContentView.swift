//
//  ContentView.swift
//  expensetracker
//
//  Created by Justin Meeks on 2/15/25.
//

import SwiftUI

struct ContentView: View {
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Housing & Utilities"
    @State private var isSplit: Bool = false
    @State private var splitPercentage: Double = 50.0
    @State private var expenses: [Expense] = []  // Array to store expenses
    
    let categories = ["Housing & Utilities", "Food", "Entertainment", "Transportation", "Other"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Amount Input
                TextField("Enter amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .border(Color.gray, width: 1)
                    .padding(.bottom)
                
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.bottom)
                
                // Split Checkbox and Split Percentage
                Toggle(isOn: $isSplit) {
                    Text("Split Amount?")
                }
                .padding(.bottom)
                
                if isSplit {
                    // Split Percentage Slider
                    Slider(value: $splitPercentage, in: 0...100, step: 1)
                        .padding(.bottom)
                    Text("Split Percentage: \(Int(splitPercentage))%")
                }
                
                // Save Button
                Button(action: saveExpense) {
                    Text("Save Expense")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Navigation to Report Page
                NavigationLink(destination: ReportView(expenses: expenses)) {
                    Text("View Report")
                        .padding(.top)
                }
                
                // Expenses List
                List {
                    ForEach(expenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("$\(String(format: "%.2f", expense.amount))")
                                    .font(.body)
                                Text(expense.category)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button("Edit") {
                                editExpense(expense)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.blue)
                        }
                    }
                    .onDelete(perform: deleteExpense)
                }
            }
            .padding()
            .navigationBarTitle("Enter Expense")
            .onAppear {
                // Load expenses when the view appears
                self.expenses = loadExpenses()
            }
        }
    }
    
    // Save the expense entry to dictionary and UserDefaults
    func saveExpense() {
        if let amountDouble = Double(amount) {
            // Calculate final amount if split
            let finalAmount = isSplit ? amountDouble * (splitPercentage / 100) : amountDouble
            let newExpense = Expense(amount: finalAmount, category: selectedCategory, date: Date())
            
            // Add to expenses array
            expenses.append(newExpense)
            
            // Save expenses to UserDefaults
            saveToUserDefaults(expenses: expenses)
            
            // Reset the input field
            amount = ""
        }
    }
    
    // Save expenses to UserDefaults
    func saveToUserDefaults(expenses: [Expense]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: "expenses")
        }
    }
    
    // Load expenses from UserDefaults
    func loadExpenses() -> [Expense] {
        if let savedData = UserDefaults.standard.data(forKey: "expenses") {
            let decoder = JSONDecoder()
            if let loadedExpenses = try? decoder.decode([Expense].self, from: savedData) {
                return loadedExpenses
            }
        }
        return []
    }
    
    // Delete an expense
    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveToUserDefaults(expenses: expenses)
    }

    // Edit an expense
    func editExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            let editedExpense = expenses[index]
            // Update values (for simplicity, edit in place for now)
            expenses[index] = editedExpense
            saveToUserDefaults(expenses: expenses)
        }
    }

    // Function to calculate the total sum of all expenses
    func totalSum() -> Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    // Function to calculate the total sum of expenses by category
    func totalSumByCategory(category: String) -> Double {
        let filteredExpenses = expenses.filter { $0.category == category }
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Function to calculate the total sum of expenses by month (grouped by month)
    func totalSumByMonth() -> [String: Double] {
        var monthSums: [String: Double] = [:]
        
        for expense in expenses {
            let month = formatDate(expense.date)
            monthSums[month, default: 0] += expense.amount
        }
        
        return monthSums
    }
    
    // Function to calculate the total sum of expenses by month and category
    func totalSumByMonthAndCategory() -> [String: [String: Double]] {
        var monthCategorySums: [String: [String: Double]] = [:]
        
        for expense in expenses {
            let month = formatDate(expense.date)
            let category = expense.category
            monthCategorySums[month, default: [:]][category, default: 0] += expense.amount
        }
        
        return monthCategorySums
    }
    
    // Helper function to format date as "YYYY-MM"
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        return dateFormatter.string(from: date)
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()  // Unique ID for each expense
    var amount: Double
    var category: String
    var date: Date
}

struct ReportView: View {
    var expenses: [Expense]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total sum of all expenses
                Text("Total Expenses")
                    .font(.title)
                    .bold()
                    .foregroundColor(.blue)
                    .padding(.top)

                Text("$\(String(format: "%.2f", totalSum()))")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Divider()
                
                // Total sum by category
                Text("Expenses by Category")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                
                ForEach(ContentView().categories, id: \.self) { category in
                    HStack {
                        Text(category)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", totalSumByCategory(category: category)))")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    Divider()
                }
                
                Divider()
                
                // Total sum by month
                Text("Expenses by Month")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                
                ForEach(totalSumByMonth().keys.sorted(), id: \.self) { month in
                    HStack {
                        Text(month)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", totalSumByMonth()[month]!))")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    Divider()
                }
                
                Divider()
                
                // Total sum by month and category
                Text("Expenses by Month & Category")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                
                ForEach(totalSumByMonthAndCategory().keys.sorted(), id: \.self) { month in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(month)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(totalSumByMonthAndCategory()[month]!.keys.sorted(), id: \.self) { category in
                            HStack {
                                Text(category)
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", totalSumByMonthAndCategory()[month]![category]!))")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                }
            }
            .padding()
        }
        .navigationBarTitle("Expense Reports", displayMode: .inline)
    }
    
    // Report functions copied from ContentView
    func totalSum() -> Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func totalSumByCategory(category: String) -> Double {
        let filteredExpenses = expenses.filter { $0.category == category }
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    func totalSumByMonth() -> [String: Double] {
        var monthSums: [String: Double] = [:]
        
        for expense in expenses {
            let month = formatDate(expense.date)
            monthSums[month, default: 0] += expense.amount
        }
        
        return monthSums
    }
    
    func totalSumByMonthAndCategory() -> [String: [String: Double]] {
        var monthCategorySums: [String: [String: Double]] = [:]
        
        for expense in expenses {
            let month = formatDate(expense.date)
            let category = expense.category
            monthCategorySums[month, default: [:]][category, default: 0] += expense.amount
        }
        
        return monthCategorySums
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        return dateFormatter.string(from: date)
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(expenses: [
            Expense(amount: 100.0, category: "Food", date: Date()),
            Expense(amount: 50.0, category: "Transportation", date: Date()),
            Expense(amount: 200.0, category: "Food", date: Date()),
            Expense(amount: 150.0, category: "Housing & Utilities", date: Date())
        ])
    }
}


#Preview {
    ContentView()
}
