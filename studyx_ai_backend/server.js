
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { GoogleGenAI } from "@google/genai";
import path from "path";
import { fileURLToPath } from "url";

// ============================================================
// ENVIRONMENT
// ============================================================

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Always load .env from THIS backend folder.
dotenv.config({
  path: path.join(__dirname, ".env"),
});

const GEMINI_API_KEY = process.env.GEMINI_API_KEY?.trim();
const PORT = process.env.PORT || 3000;

// ============================================================
// VALIDATE CONFIGURATION
// ============================================================

if (!GEMINI_API_KEY) {
  console.error("❌ GEMINI_API_KEY is missing.");
  console.error("Expected .env file:");
  console.error(path.join(__dirname, ".env"));
  process.exit(1);
}

console.log("StudyX AI configuration:");
console.log("  Backend folder:", __dirname);
console.log("  API key found:", true);

// ============================================================
// APP
// ============================================================

const app = express();

app.use(cors());
app.use(express.json({ limit: "1mb" }));

// ============================================================
// GEMINI
// ============================================================

const ai = new GoogleGenAI({
  apiKey: GEMINI_API_KEY,
});

// ============================================================
// SYSTEM PROMPT
// ============================================================

const SYSTEM_PROMPT = `
You are StudyX AI, an intelligent personal study assistant.

Your job is to help students study smarter using their actual StudyX data.

CORE BEHAVIOR:

1. Understand the student's actual situation.
2. Prioritize upcoming exams and unfinished topics.
3. Give realistic study plans.
4. Never invent syllabus, marks, progress, or schedule information.
5. Explain concepts at the student's level.
6. For revision, use active recall, questions and spaced revision.
7. When asked what to study, give clear priorities.
8. When asked for a plan, give a practical time-based plan.
9. Keep answers clear and useful.
10. Avoid unnecessary information.

STUDY MODES:

QUICK_HELP
EXPLANATION
REVISION
QUIZ
STUDY_PLAN
EXAM_PREP
PROGRESS_ANALYSIS
SYLLABUS_ANALYSIS
TASK_PLANNING
GENERAL_CHAT

Use this structure when useful:

Goal
Priority
Plan
Why
Next action

Use only the supplied student context.
`;

// ============================================================
// STUDENT CONTEXT
// ============================================================

function buildStudentContext(data) {
  return `
STUDENT CONTEXT

Name:
${data.user?.name || "Student"}

Goal:
${data.user?.goal || "Not specified"}

Daily study hours:
${data.user?.dailyHours ?? "Not specified"}

SYLLABUS:
${JSON.stringify(data.syllabus ?? [], null, 2)}

TASKS:
${JSON.stringify(data.tasks ?? [], null, 2)}

STUDY SESSIONS:
${JSON.stringify(data.studySessions ?? [], null, 2)}

RECENT CONVERSATION:
${JSON.stringify(data.messages ?? [], null, 2)}
`;
}

// ============================================================
// HEALTH
// ============================================================

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    service: "StudyX AI",
  });
});

// ============================================================
// AI CHAT
// ============================================================

app.post("/api/ai/chat", async (req, res) => {
  try {
    const {
      message,
      user,
      syllabus,
      tasks,
      studySessions,
      messages,
    } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        error: "Message is required.",
      });
    }

    const studentContext = buildStudentContext({
      user,
      syllabus,
      tasks,
      studySessions,
      messages,
    });

    const prompt = `
${SYSTEM_PROMPT}

${studentContext}

USER MESSAGE:
${message.trim()}
`;

    console.log("StudyX AI request received.");

    const response = await ai.models.generateContent({
      model: "gemini-3.6-flash",
      contents: prompt,
    });

    const answer = response.text?.trim();

    if (!answer) {
      throw new Error("Gemini returned an empty response.");
    }

    console.log("StudyX AI response generated successfully.");

    return res.json({
      success: true,
      answer: answer,
    });

  } catch (error) {
    console.error("========================================");
    console.error("StudyX AI ERROR");
    console.error("========================================");
    console.error(error?.message || error);
    console.error("========================================");

    return res.status(500).json({
      success: false,
      error: error?.message || String(error),
    });
  }
});

// ============================================================
// START SERVER
// ============================================================

app.listen(PORT, () => {
  console.log("----------------------------------------");
  console.log(`StudyX AI backend running on port ${PORT}`);
  console.log("----------------------------------------");
});
