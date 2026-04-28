class RagEvalCase {
  const RagEvalCase({
    required this.id,
    required this.question,
    required this.expectedStatus,
    this.expectedDoc,
    this.expectedChunk,
    this.allowPartial = false,
    this.isFollowUp = false,
    this.followUpQuestion = '',
    this.category = 'baseline',
  });

  final int id;
  final String question;
  final String expectedStatus;
  final String? expectedDoc;
  final int? expectedChunk;
  final bool allowPartial;
  final bool isFollowUp;
  final String followUpQuestion;
  final String category;
}

const ragEvalCases = [
  RagEvalCase(
    id: 1,
    question: 'DOSBox 0.74 supports which CPU emulation cores?',
    expectedStatus: 'exists',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 12,
  ),
  RagEvalCase(
    id: 2,
    question: 'What is the default key to release the mouse in DOSBox?',
    expectedStatus: 'exists',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 8,
  ),
  RagEvalCase(
    id: 3,
    question: 'Which configuration file does DOSBox load on startup?',
    expectedStatus: 'exists',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 3,
  ),
  RagEvalCase(
    id: 4,
    question: 'What command lists keyboard layouts?',
    expectedStatus: 'exists',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 45,
  ),
  RagEvalCase(
    id: 5,
    question: 'What is the maximum supported CPU cycles setting?',
    expectedStatus: 'exists',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 18,
  ),
  RagEvalCase(
    id: 6,
    question: 'What is the price of DOSBox Pro Edition?',
    expectedStatus: 'missing',
  ),
  RagEvalCase(
    id: 7,
    question: 'Who is the CEO of DOSBox?',
    expectedStatus: 'missing',
  ),
  RagEvalCase(
    id: 8,
    question: "What's the deadline for v2.0 release?",
    expectedStatus: 'missing',
  ),
  RagEvalCase(
    id: 9,
    question: 'How do I let go of the mouse cursor?',
    expectedStatus: 'synonym',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 8,
  ),
  RagEvalCase(
    id: 10,
    question: 'Tell me about CPU speed control.',
    expectedStatus: 'synonym',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 18,
  ),
  RagEvalCase(
    id: 11,
    question: "What's the keyboard mapping command?",
    expectedStatus: 'synonym',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 45,
  ),
  RagEvalCase(
    id: 12,
    question: 'How do I configure DOSBox on Windows?',
    expectedStatus: 'followUp',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 5,
    allowPartial: true,
    isFollowUp: true,
    followUpQuestion: 'And what about MacOS?',
  ),
  RagEvalCase(
    id: 13,
    question: 'Explain CPU cycles in DOSBox.',
    expectedStatus: 'followUp',
    expectedDoc: 'DOSBox 0.74 Manual.txt',
    expectedChunk: 18,
    isFollowUp: true,
    followUpQuestion: 'Can you give an example?',
  ),
];
