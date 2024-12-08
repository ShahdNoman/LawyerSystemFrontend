-- Database: `justipro`

-- Table structure for table `notifications`
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notification_type` enum('Case', 'Session', 'Payment', 'Message', 'General') DEFAULT NULL,
  `message` text DEFAULT NULL,
  `send_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_read` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `complaints`
CREATE TABLE `complaints` (
  `id` int(11) NOT NULL,
  `case_id` int(11) DEFAULT NULL,
  `complaint_type` enum('Against_Lawyer', 'Against_Judge', 'Against_System') NOT NULL,
  `complaint_details` text NOT NULL,
  `complainant_id` int(11) DEFAULT NULL,
  `accused_id` int(11) DEFAULT NULL,
  `complaint_status` enum('Open', 'In_Progress', 'Closed') DEFAULT 'Open',
  `creation_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `tokens`
CREATE TABLE `tokens` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `token_value` varchar(255) DEFAULT NULL,
  `issue_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `expiration_time` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `sessions`
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL,
  `case_id` int(11) DEFAULT NULL,
  `session_date` date DEFAULT NULL,
  `session_details` text DEFAULT NULL,
  `session_status` enum('Postponed', 'Completed', 'Pending') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `cases`
CREATE TABLE `cases` (
  `id` int(11) NOT NULL,
  `case_number` varchar(50) NOT NULL,
  `case_type` enum('Civil', 'Criminal', 'Settlement', 'Appeal', 'Cassation') NOT NULL,
  `case_status` enum('Ongoing', 'Closed', 'Execution') NOT NULL,
  `plaintiff_id` int(11) DEFAULT NULL,
  `defendant_id` int(11) DEFAULT NULL,
  `lawyer_id` int(11) DEFAULT NULL,
  `judge_id` int(11) DEFAULT NULL,
  `court_name` varchar(200) DEFAULT NULL,
  `court_type` enum('Primary', 'Appeal', 'Cassation', 'Settlement') DEFAULT NULL,
  `session_date` date DEFAULT NULL,
  `session_status` enum('Postponed', 'Pending', 'Completed') DEFAULT NULL,
  `next_session_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `conversations`
CREATE TABLE `conversations` (
  `id` int(11) NOT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `receiver_id` int(11) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `message_type` enum('Text', 'File', 'Link') DEFAULT NULL,
  `send_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_read` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `payments`
CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `case_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `payment_status` enum('Completed', 'Pending', 'Deferred') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `attachments`
CREATE TABLE `attachments` (
  `id` int(11) NOT NULL,
  `case_id` int(11) DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `uploaded_by_user_id` int(11) DEFAULT NULL,
  `upload_time` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `users`
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Admin', 'Lawyer', 'Citizen', 'Judge') NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `full_name` varchar(200) DEFAULT NULL,
  `membership_number` varchar(50) DEFAULT NULL,
  `judge_number` varchar(50) DEFAULT NULL,
  `id_number` varchar(20) DEFAULT NULL,
  `registration_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('Active', 'Inactive') DEFAULT 'Active',
  `profile_picture` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Indexes for dumped tables
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `complaints`
  ADD PRIMARY KEY (`id`),
  ADD KEY `case_id` (`case_id`),
  ADD KEY `complainant_id` (`complainant_id`),
  ADD KEY `accused_id` (`accused_id`);


ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `case_id` (`case_id`);

ALTER TABLE `cases`
  ADD PRIMARY KEY (`id`),
  ADD KEY `plaintiff_id` (`plaintiff_id`),
  ADD KEY `defendant_id` (`defendant_id`),
  ADD KEY `lawyer_id` (`lawyer_id`),
  ADD KEY `judge_id` (`judge_id`);

ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `case_id` (`case_id`);

ALTER TABLE `attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `case_id` (`case_id`),
  ADD KEY `uploaded_by_user_id` (`uploaded_by_user_id`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

-- AUTO_INCREMENT for dumped tables
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `complaints`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `cases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `attachments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

-- Constraints for dumped tables
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

ALTER TABLE `complaints`
  ADD CONSTRAINT `complaints_ibfk_1` FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`);
