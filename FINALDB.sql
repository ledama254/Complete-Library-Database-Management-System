-- Library Management System Database
-- Created by [Your Name]
-- Date: [Current Date]

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Members table (1-1 with LibraryCard)
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    date_of_birth DATE,
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    membership_status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
);

-- LibraryCards table (1-1 with Members)
CREATE TABLE LibraryCards (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNIQUE NOT NULL,
    card_number VARCHAR(20) UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_dates CHECK (expiry_date > issue_date)
);

-- Authors table
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year YEAR,
    death_year YEAR,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT chk_life CHECK (death_year IS NULL OR death_year >= birth_year)
);

-- Publishers table
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    founding_year YEAR,
    CONSTRAINT chk_website CHECK (website LIKE 'http%')
);

-- Books table
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    publisher_id INT,
    publication_year YEAR,
    edition INT DEFAULT 1,
    category VARCHAR(50),
    language VARCHAR(30) DEFAULT 'English',
    page_count INT,
    description TEXT,
    FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id) ON DELETE SET NULL,
    CONSTRAINT chk_pages CHECK (page_count > 0)
);

-- BookAuthors table (M-M relationship between Books and Authors)
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type VARCHAR(50) DEFAULT 'Author',
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- BookCopies table (1-M relationship with Books)
CREATE TABLE BookCopies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    acquisition_date DATE NOT NULL,
    price DECIMAL(10,2),
    condition ENUM('New', 'Good', 'Fair', 'Poor', 'Lost') DEFAULT 'Good',
    location VARCHAR(50),
    status ENUM('Available', 'Checked Out', 'On Hold', 'Lost', 'Removed') DEFAULT 'Available',
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT chk_price CHECK (price >= 0)
);

-- Loans table (M-M relationship between Members and BookCopies)
CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    return_date DATETIME,
    late_fee DECIMAL(10,2) DEFAULT 0,
    status ENUM('Active', 'Returned', 'Overdue', 'Lost') DEFAULT 'Active',
    FOREIGN KEY (copy_id) REFERENCES BookCopies(copy_id),
    FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT chk_due_date CHECK (due_date > DATE(checkout_date)),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Holds table
CREATE TABLE Holds (
    hold_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    request_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATETIME,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    priority INT,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_expiration CHECK (expiration_date > request_date)
);

-- Fines table (1-M relationship with Members)
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    loan_id INT,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('Outstanding', 'Paid', 'Waived') DEFAULT 'Outstanding',
    reason VARCHAR(200),
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (loan_id) REFERENCES Loans(loan_id) ON DELETE SET NULL,
    CONSTRAINT chk_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment CHECK (payment_date IS NULL OR payment_date >= issue_date)
);

-- Staff table
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    supervisor_id INT,
    FOREIGN KEY (supervisor_id) REFERENCES Staff(staff_id) ON DELETE SET NULL,
    CONSTRAINT chk_salary CHECK (salary >= 0)
);

-- LibraryBranches table
CREATE TABLE LibraryBranches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    opening_hours VARCHAR(100),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES Staff(staff_id) ON DELETE SET NULL
);

-- StaffAssignments table (M-M relationship between Staff and LibraryBranches)
CREATE TABLE StaffAssignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    branch_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    role VARCHAR(50) NOT NULL,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES LibraryBranches(branch_id) ON DELETE CASCADE,
    CONSTRAINT chk_assignment_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Create indexes for performance
CREATE INDEX idx_books_title ON Books(title);
CREATE INDEX idx_books_isbn ON Books(isbn);
CREATE INDEX idx_members_name ON Members(last_name, first_name);
CREATE INDEX idx_members_email ON Members(email);
CREATE INDEX idx_loans_member ON Loans(member_id);
CREATE INDEX idx_loans_copy ON Loans(copy_id);
CREATE INDEX idx_loans_due_date ON Loans(due_date);
CREATE INDEX idx_fines_member ON Fines(member_id);