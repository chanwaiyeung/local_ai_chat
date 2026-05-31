/*
 * ==============================================================================
 * LOCAL AI OFFICE BRIDGE - OFFICE.JS ADD-IN TEMPLATE (REVISED)
 * ==============================================================================
 *
 * This code demonstrates how to build a modern Microsoft Office Add-in
 * task pane javascript script that communicates with the local AI server
 * on port 61670.
 *
 * Requirements:
 * 1. Office Add-in project scaffold (built via yo office)
 * 2. An active taskpane HTML interface linking to this javascript file.
 *
 * ==============================================================================
 */

/**
 * Polish selected text in Word documents.
 */
async function polishSelectedText() {
  await Word.run(async (context) => {
    // 1. Get current selection from document
    const range = context.document.getSelection();
    range.load("text");
    await context.sync();

    // 2. Validate selection
    if (!range.text || range.text.trim() === "") {
      showNotification("Warning", "Please select some text first!");
      return;
    }

    try {
      showLoading(true);

      // 3. Post payload to Local AI Office Bridge
      const response = await fetch("http://127.0.0.1:61670/office/ask", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          app: "word",
          task: "polish",
          text: range.text,
          tone: "formal",
          target: "zh-TW"
        })
      });

      // 4. Update document with response
      if (response.ok) {
        const data = await response.json();
        if (data.ok && data.result) {
          range.insertText(data.result, Word.InsertLocation.replace);
          await context.sync();
        } else {
          showNotification("Error", "Received empty response or request failed.");
        }
      } else {
        showNotification("HTTP Error", "Server returned status code: " + response.status);
      }
    } catch (error) {
      showNotification("Connection Error", "Ensure the Flutter Desktop app is running.");
      console.error("Fetch failed: ", error);
    } finally {
      showLoading(false);
    }
  });
}

/**
 * Generate Excel formula into the active cell based on description.
 */
async function generateExcelFormula() {
  await Excel.run(async (context) => {
    // 1. Get the active cell and load its text value
    const cell = context.workbook.getActiveCell();
    cell.load("values");
    await context.sync();

    const descriptionText = cell.values[0][0];
    if (!descriptionText || descriptionText.trim() === "") {
      showNotification("Warning", "Enter a natural language description in the active cell.");
      return;
    }

    try {
      showLoading(true);

      // 2. Query Local AI
      const response = await fetch("http://127.0.0.1:61670/office/ask", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          app: "excel",
          task: "formula",
          text: descriptionText,
          tone: "formula",
          target: "zh-TW"
        })
      });

      // 3. Place formula in the cell to the right (offset 0, 1)
      if (response.ok) {
        const data = await response.json();
        if (data.ok && data.result) {
          const targetCell = cell.getOffsetRange(0, 1);
          targetCell.values = [[data.result]];
          await context.sync();
        }
      } else {
        showNotification("HTTP Error", "Excel API request failed.");
      }
    } catch (error) {
      showNotification("Error", "Could not connect to Local AI Server.");
    } finally {
      showLoading(false);
    }
  });
}

/**
 * Generate PowerPoint slides from outline text pasted/entered in the sidebar.
 */
async function createSlidesFromOutline() {
  const outlineInput = document.getElementById("outline-input");
  const outlineText = outlineInput ? outlineInput.value : "";

  if (!outlineText || outlineText.trim() === "") {
    showNotification("Warning", "Please enter or paste an outline first!");
    return;
  }

  try {
    showLoading(true);

    const response = await fetch("http://127.0.0.1:61670/office/ask", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        app: "ppt",
        task: "outline",
        text: outlineText,
        tone: "professional",
        target: "zh-TW"
      })
    });

    if (response.ok) {
      const data = await response.json();
      if (data.ok && data.result) {
        let jsonText = data.result.trim();
        // Clean up markdown block wrapper if present
        if (jsonText.startsWith("```")) {
          jsonText = jsonText.replace(/^```(json)?\n/, "").replace(/\n```$/, "");
        }

        const slidesData = JSON.parse(jsonText);
        if (Array.isArray(slidesData)) {
          await PowerPoint.run(async (context) => {
            for (let i = 0; i < slidesData.length; i++) {
              const slideData = slidesData[i];
              const title = slideData.title || `Slide ${i + 1}`;
              const bullets = slideData.bullets || [];
              const speakerNotes = slideData.speaker_notes || "";
              const suggestedVisual = slideData.suggested_visual || "";

              // Add a slide
              const slide = context.presentation.slides.add();

              // Add Title Text Box (typical position: left: 50, top: 50, width: 620, height: 80)
              const titleBox = slide.shapes.addTextBox(title, {
                left: 50,
                top: 50,
                width: 620,
                height: 80
              });
              titleBox.textFrame.textRange.font.bold = true;
              titleBox.textFrame.textRange.font.size = 36;
              titleBox.textFrame.textRange.font.color = "#333333";

              // Add Bullets Text Box (typical position: left: 50, top: 150, width: 620, height: 300)
              const bulletText = bullets.map(b => "• " + b).join("\n");
              const bulletsBox = slide.shapes.addTextBox(bulletText, {
                left: 50,
                top: 150,
                width: 620,
                height: 300
              });
              bulletsBox.textFrame.textRange.font.size = 18;
              bulletsBox.textFrame.textRange.font.color = "#555555";

              // Since speaker notes API is not supported by Office.js PowerPoint API,
              // we display them along with the suggested visual at the bottom in an italic style
              let footerText = "";
              if (suggestedVisual) {
                footerText += `[Suggested Visual: ${suggestedVisual}] `;
              }
              if (speakerNotes) {
                footerText += `\n[Notes: ${speakerNotes}]`;
              }
              
              if (footerText.trim()) {
                const footerBox = slide.shapes.addTextBox(footerText.trim(), {
                  left: 50,
                  top: 460,
                  width: 620,
                  height: 60
                });
                footerBox.textFrame.textRange.font.italic = true;
                footerBox.textFrame.textRange.font.size = 12;
                footerBox.textFrame.textRange.font.color = "#777777";
              }
            }
            await context.sync();
          });
          showNotification("Success", `Created ${slidesData.length} slides successfully!`);
        } else {
          showNotification("Error", "Invalid JSON structure received from AI.");
        }
      } else {
        showNotification("Error", "No slides data returned from AI.");
      }
    } else {
      showNotification("HTTP Error", "Server returned status: " + response.status);
    }
  } catch (error) {
    showNotification("Error", "Failed to generate slides. Error: " + error.message);
    console.error("PPT generation error:", error);
  } finally {
    showLoading(false);
  }
}

// ----------------------------- UI Helpers -----------------------------

function showLoading(isLoading) {
  const loader = document.getElementById("loader");
  if (loader) {
    loader.style.display = isLoading ? "block" : "none";
  }
}

function showNotification(title, message) {
  console.log(`[${title}]: ${message}`);
  const statusDiv = document.getElementById("status-message");
  if (statusDiv) {
    statusDiv.innerText = `${title}: ${message}`;
  }
}
