$(function() {
    subject_data = [
      { title: "Language Arts", label: "Language Arts" },{ title: "Mathematics", label: "Mathematics" },{ title: "Science", label: "Science" },{ title: "Health", label: "Health" },{ title: "Handwriting", label: "Handwriting" },{ title: "Physical Education (P.E.)", label: "Physical Education (P.E.)" },{ title: "Art", label: "Art" },{ title: "Music", label: "Music" },{ title: "Movement or Eurythmy", label: "Movement or Eurythmy" },{ title: "Handwork or handcrafts", label: "Handwork or handcrafts" },{ title: "Life Lab or gardening", label: "Life Lab or gardening" },{ title: "Dramatics", label: "Dramatics" },{ title: "Dance", label: "Dance" },{ title: "Spanish or other foreign language", label: "Spanish or other foreign language" },{ title: "Leadership", label: "Leadership" },{ title: "Special Education Day Class", label: "Special Education Day Class" },{ title: "Resource Program", label: "Resource Program" },{ title: "Speech", label: "Speech" },{ title: "Adaptive P.E.", label: "Adaptive P.E." },{ title: "Occupational Therapy", label: "Occupational Therapy" },{ title: "Middle School Subjects", label: "Middle School Subjects" },{ title: "Reading", label: "Reading" },{ title: "Speech and Debate", label: "Speech and Debate" },{ title: "English", label: "English" },{ title: "Basic Math", label: "Basic Math" },{ title: "Pre-algebra", label: "Pre-algebra" },{ title: "Consumer Math", label: "Consumer Math" },{ title: "Algebra", label: "Algebra" },{ title: "Geometry", label: "Geometry" },{ title: "Honors Math in Algebra or Geometry", label: "Honors Math in Algebra or Geometry" },{ title: "Life Science", label: "Life Science" },{ title: "Earth Science", label: "Earth Science" },{ title: "Physical Science", label: "Physical Science" },{ title: "Social Studies", label: "Social Studies" },{ title: "Geography", label: "Geography" },{ title: "Ancient Civilizations", label: "Ancient Civilizations" },{ title: "Medieval and Renaissance", label: "Medieval and Renaissance" },{ title: "U.S. History and Government", label: "U.S. History and Government" },{ title: "French / Spanish / Latin", label: "French / Spanish / Latin" },{ title: "Computer Lab", label: "Computer Lab" },{ title: "Computer Science", label: "Computer Science" },{ title: "Home Economics", label: "Home Economics" },{ title: "Woodshop", label: "Woodshop" },{ title: "Metal Shop", label: "Metal Shop" },{ title: "Business Technology", label: "Business Technology" },{ title: "Instrumental Music", label: "Instrumental Music" },{ title: "Band", label: "Band" },{ title: "Choir", label: "Choir" },{ title: "Drama", label: "Drama" },{ title: "Physical Education", label: "Physical Education" },{ title: "Sports", label: "Sports" },{ title: "Speech Therapy", label: "Speech Therapy" },{ title: "High School Subjects", label: "High School Subjects" },{ title: "English I", label: "English I" },{ title: "English II", label: "English II" },{ title: "English III", label: "English III" },{ title: "English IV", label: "English IV" },{ title: "Remedial English", label: "Remedial English" },{ title: "World Literature", label: "World Literature" },{ title: "Ancient Literature", label: "Ancient Literature" },{ title: "Medieval Literature", label: "Medieval Literature" },{ title: "Renaissance Literature", label: "Renaissance Literature" },{ title: "Modern Literature", label: "Modern Literature" },{ title: "British Literature", label: "British Literature" },{ title: "American Literature", label: "American Literature" },{ title: "Composition", label: "Composition" },{ title: "Creative Writing", label: "Creative Writing" },{ title: "Poetry", label: "Poetry" },{ title: "Grammar", label: "Grammar" },{ title: "Vocabulary", label: "Vocabulary" },{ title: "Debate", label: "Debate" },{ title: "Journalism", label: "Journalism" },{ title: "Publishing Skills", label: "Publishing Skills" },{ title: "Photojournalism", label: "Photojournalism" },{ title: "Yearbook", label: "Yearbook" },{ title: "Study Skills", label: "Study Skills" },{ title: "Research Skills", label: "Research Skills" },{ title: "Fine Arts", label: "Fine Arts" },{ title: "Art I", label: "Art I" },{ title: "Art II", label: "Art II" },{ title: "Art III", label: "Art III" },{ title: "Art IV", label: "Art IV" },{ title: "Art Appreciation", label: "Art Appreciation" },{ title: "Art History", label: "Art History" },{ title: "Drawing", label: "Drawing" },{ title: "Painting", label: "Painting" },{ title: "Sculpture", label: "Sculpture" },{ title: "Ceramics", label: "Ceramics" },{ title: "Pottery", label: "Pottery" },{ title: "Music Appreciation", label: "Music Appreciation" },{ title: "Music History", label: "Music History" },{ title: "Music Theory", label: "Music Theory" },{ title: "Music Fundamentals", label: "Music Fundamentals" },{ title: "Orchestra", label: "Orchestra" },{ title: "Voice", label: "Voice" },{ title: "Classical Music Studies", label: "Classical Music Studies" },{ title: "Performing Arts", label: "Performing Arts" },{ title: "Theatre Arts", label: "Theatre Arts" },{ title: "Improvisational Theater", label: "Improvisational Theater" },{ title: "Computer Aided Design", label: "Computer Aided Design" },{ title: "Digital Media", label: "Digital Media" },{ title: "Photography", label: "Photography" },{ title: "Videography", label: "Videography" },{ title: "History of Film", label: "History of Film" },{ title: "Film Production", label: "Film Production" },{ title: "Leather Working", label: "Leather Working" },{ title: "Drafting", label: "Drafting" },{ title: "Metal Work", label: "Metal Work" },{ title: "Small Engine Mechanics", label: "Small Engine Mechanics" },{ title: "Auto Mechanics", label: "Auto Mechanics" },{ title: "General Science", label: "General Science" },{ title: "Physics", label: "Physics" },{ title: "Chemistry", label: "Chemistry" },{ title: "Organic Chemistry", label: "Organic Chemistry" },{ title: "Biology", label: "Biology" },{ title: "Zoology", label: "Zoology" },{ title: "Marine Biology", label: "Marine Biology" },{ title: "Botany", label: "Botany" },{ title: "Geology", label: "Geology" },{ title: "Oceanography", label: "Oceanography" },{ title: "Meteorology", label: "Meteorology" },{ title: "Astronomy", label: "Astronomy" },{ title: "Animal Science", label: "Animal Science" },{ title: "Equine Science", label: "Equine Science" },{ title: "Veterinary Science", label: "Veterinary Science" },{ title: "Forensic Science", label: "Forensic Science" },{ title: "Ecology", label: "Ecology" },{ title: "Environmental Science", label: "Environmental Science" },{ title: "Gardening", label: "Gardening" },{ title: "Food Science", label: "Food Science" },{ title: "Spanish", label: "Spanish" },{ title: "French", label: "French" },{ title: "Japanese", label: "Japanese" },{ title: "German", label: "German" },{ title: "Latin", label: "Latin" },{ title: "Greek", label: "Greek" },{ title: "Hebrew", label: "Hebrew" },{ title: "Chinese", label: "Chinese" },{ title: "Sign Language", label: "Sign Language" },{ title: "Remedial Math", label: "Remedial Math" },{ title: "Fundamental Math or Basic Math", label: "Fundamental Math or Basic Math" },{ title: "Introduction to Algebra", label: "Introduction to Algebra" },{ title: "Algebra I", label: "Algebra I" },{ title: "Algebra II", label: "Algebra II" },{ title: "Intermediate Algebra", label: "Intermediate Algebra" },{ title: "Trigonometry", label: "Trigonometry" },{ title: "Precalculus", label: "Precalculus" },{ title: "Calculus", label: "Calculus" },{ title: "Statistics", label: "Statistics" },{ title: "Business Math", label: "Business Math" },{ title: "Accounting", label: "Accounting" },{ title: "Personal Finance and Investing", label: "Personal Finance and Investing" },{ title: "Ancient History", label: "Ancient History" },{ title: "Medieval History", label: "Medieval History" },{ title: "Greek and Roman History", label: "Greek and Roman History" },{ title: "Renaissance History with US History", label: "Renaissance History with US History" },{ title: "Modern History with US History", label: "Modern History with US History" },{ title: "World History", label: "World History" },{ title: "World Geography", label: "World Geography" },{ title: "US History", label: "US History" },{ title: "World Religions", label: "World Religions" },{ title: "World Current Events", label: "World Current Events" },{ title: "Global Issues", label: "Global Issues" },{ title: "Government", label: "Government" },{ title: "Civics", label: "Civics" },{ title: "Economics", label: "Economics" },{ title: "Political Science", label: "Political Science" },{ title: "Social Sciences", label: "Social Sciences" },{ title: "Psychology", label: "Psychology" },{ title: "Sociology", label: "Sociology" },{ title: "Anthropology", label: "Anthropology" },{ title: "Genealogy", label: "Genealogy" },{ title: "Philosophy", label: "Philosophy" },{ title: "Logic I", label: "Logic I" },{ title: "Logic II", label: "Logic II" },{ title: "Critical Thinking", label: "Critical Thinking" },{ title: "Rhetoric", label: "Rhetoric" },{ title: "Basic First Aid and Safety", label: "Basic First Aid and Safety" },{ title: "Nutrition", label: "Nutrition" },{ title: "Healthful Living", label: "Healthful Living" },{ title: "Personal Health", label: "Personal Health" },{ title: "Team Sports", label: "Team Sports" },{ title: "Gymnastics", label: "Gymnastics" },{ title: "Track and Field", label: "Track and Field" },{ title: "Archery", label: "Archery" },{ title: "Fencing", label: "Fencing" },{ title: "Golf", label: "Golf" },{ title: "Rock Climbing", label: "Rock Climbing" },{ title: "Outdoor Survival Skills", label: "Outdoor Survival Skills" },{ title: "Hiking", label: "Hiking" },{ title: "Equestrian Skills", label: "Equestrian Skills" },{ title: "Weightlifting", label: "Weightlifting" },{ title: "Physical Fitness", label: "Physical Fitness" },{ title: "Aerobics", label: "Aerobics" },{ title: "Yoga", label: "Yoga" },{ title: "Martial Arts", label: "Martial Arts" },{ title: "Ice Skating", label: "Ice Skating" },{ title: "Figure skating", label: "Figure skating" },{ title: "Cycling", label: "Cycling" },{ title: "Bowling", label: "Bowling" },{ title: "Drill Team, Honor Guard, Pageantry, Flag, Cheer", label: "Drill Team, Honor Guard, Pageantry, Flag, Cheer" },{ title: "Adapted P.E", label: "Adapted P.E" },{ title: "Keyboarding", label: "Keyboarding" },{ title: "Word Processing", label: "Word Processing" },{ title: "Computer Aided Drafting", label: "Computer Aided Drafting" },{ title: "Computer Applications", label: "Computer Applications" },{ title: "Computer Graphics", label: "Computer Graphics" },{ title: "Digital Arts", label: "Digital Arts" },{ title: "Photoshop", label: "Photoshop" },{ title: "Programming", label: "Programming" },{ title: "Computer Repair", label: "Computer Repair" },{ title: "Web Design", label: "Web Design" },{ title: "Desktop Publishing", label: "Desktop Publishing" },{ title: "Culinary Arts", label: "Culinary Arts" },{ title: "Child Development", label: "Child Development" },{ title: "Home Management", label: "Home Management" },{ title: "Home Organization", label: "Home Organization" },{ title: "Basic Yard Care", label: "Basic Yard Care" },{ title: "Financial Management", label: "Financial Management" },{ title: "Driver's Education", label: "Driver's Education" },{ title: "Personal Organization", label: "Personal Organization" },{ title: "Social Skills", label: "Social Skills" },{ title: "Career Planning", label: "Career Planning" },{ title: "AP Courses in any core subject", label: "AP Courses in any core subject" },{ title: "Honors Courses in any core subject", label: "Honors Courses in any core subject" },{ title: "SAT Prep", label: "SAT Prep" },{ title: "Work-Study", label: "Work-Study" },{ title: "Lifeskills", label: "Lifeskills" },{ title: "Special Day Class", label: "Special Day Class" }

    ];


    grade_data = [
      { title: "Preschool", label: "Preschool PS" },
      { title: "Kindergarten", label: "Kindergarten K" },
      { title: "1st", label: "1st First Grade" },
      { title: "2nd", label: "2nd Second Grade" },
      { title: "3rd", label: "3rd Third Grade" },
      { title: "4th", label: "4th Fourth Grade" },
      { title: "5th", label: "5th Fifth Grade" },
      { title: "6th", label: "6th Sixth Grade" },
      { title: "7th", label: "7th Seventh Grade" },
      { title: "8th", label: "8th Eighth Grade" },
      { title: "9th", label: "9th Ninth Grade" },
      { title: "10th", label: "10th Tenth Grade" },
      { title: "11th", label: "11th Eleventh Grade" },
      { title: "12th", label: "12th Twelfth Grade" }
      


    ];


});