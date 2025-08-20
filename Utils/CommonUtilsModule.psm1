# This script contains utility functions for various system tasks.

# Clears the event log using the Windows Event Viewer
function CleanEventLog {
    write-host "Cleaning event log..."
}

# Dumps the event log using the Windows Event Viewer
function DumpEventLog {
    write-host "Dumping event log..."
}

# Open the hosts file in Notepad with elevated privileges
function HostsFile {
    Start-Process notepad "$env:SystemRoot\System32\drivers\etc\hosts" -Verb runAs
}



# Adds a predefined string to clipboard based on type parameter
function AiExpander {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("email", "prompt", "summarizetext", "summarizetopic", "brainstorm", "expert", "askme", "faketool", "extract", "plan")]
        [string]$Type,
        [string]$AdditionalInfo
    )
    
    $clipboardText = switch ($Type) {
        "email" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a information for the email." -ForegroundColor Red
                return
            }

            write-host "Prompt: Write a professional email with the following information: $AdditionalInfo"
            gemini -p "Write a professional email with the following information: $AdditionalInfo. Format the response in markdown."
        }
        "prompt" { 
            if (!$AdditionalInfo) {
                Write-Host "Please provide a prompt for the AI to expand." -ForegroundColor Red
                return
            }

            write-host "Prompt: $AdditionalInfo"
            gemini -p "$AdditionalInfo Format the response in markdown with appropriate headers, bullet points, and formatting."
        }
        "summarizetext" {
            if ($AdditionalInfo) {
                gemini -p "Summarize this text in markdown format with headers and bullet points: $AdditionalInfo"
            }
            else {
                gemini -p "Summarize this text in markdown format with headers and bullet points."
            }
        }
        "summarizetopic" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a topic for the summarization." -ForegroundColor Red
                return
            }

            write-host "Prompt: You are a ghostwriter researching this topic: $AdditionalInfo. Summarize key insights from books, articles, blogs, forums, and papers. Write like a pro."
            gemini -p "You are a ghostwriter researching this topic: $AdditionalInfo. Summarize key insights from books, articles, blogs, forums, and papers. Write like a pro. Format the response in markdown with headers, bullet points, and proper structure."
        }
        "brainstorm" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a topic for the brainstorming session." -ForegroundColor Red
                return
            }

            write-host "Prompt: Brainstorm ideas for: $AdditionalInfo"
            gemini -p "Brainstorm ideas for: $AdditionalInfo. Format the response in markdown with headers and organized bullet points."
        }
        "expert" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a 'topic:question' for the expert-level response." -ForegroundColor Red
                return
            }

            $topic = $AdditionalInfo.Split(":")[0]
            $question = $AdditionalInfo.Split(":")[1]

            if (!$question) {
                Write-Host "Please provide a 'question' for the expert-level response." -ForegroundColor Red
                return
            }

            write-host "Prompt: Act as an expert in $topic with 20+ years of experience. Don't simplify - use advanced concepts and expert-level terminology. Answer the following question: $question"
            gemini -p "Act as an expert in $topic with 20+ years of experience. Don't simplify - use advanced concepts and expert-level terminology. Answer the following question: $question. Format the response in markdown with proper headers, code blocks where appropriate, and structured content."
        }
        "askme" {
            write-host "Ask me 5 questions to understand my situation, then give me tailored advice."
            gemini -p "Ask me 5 questions to understand my situation, then give me tailored advice. Format the response in markdown with numbered questions and structured advice sections."
        }
        "faketool" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a 'tool:question' for the expert-level response." -ForegroundColor Red
                return
            }
            $tool = $AdditionalInfo.Split(":")[0]
            $question = $AdditionalInfo.Split(":")[1]
            
            if (!$question) {
                Write-Host "Please provide a 'question' for the expert-level response." -ForegroundColor Red
                return
            }

            write-host "Prompt: Pretend you have access to $tool. Use similar logic and data to give me full insights. $question"
            gemini -p "Pretend you have access to $tool. Use similar logic and data to give me full insights. $question. Format the response in markdown with headers, data tables, and structured analysis."
        }
        "extract" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a 'tool:question' for this to work." -ForegroundColor Red
                return
            }

            write-host "Prompt: Here's a chunk of messy data $AdditionalInfo. Clean, categorize, and summarize it into a table."
            gemini -p "Here's a chunk of messy data $AdditionalInfo. Clean, categorize, and summarize it into a markdown table with proper headers and formatting."
        }
        "plan" {
            if (!$AdditionalInfo) {
                Write-Host "Please provide a 'goal:skills:time' this to work." -ForegroundColor Red
                return
            }

            $goal = $AdditionalInfo.Split(":")[0]
            $skills = $AdditionalInfo.Split(":")[1]
            $time = $AdditionalInfo.Split(":")[2]

            if (!$goal) {
                Write-Host "Please provide a 'goal' for the expert-level response." -ForegroundColor Red
                return
            }
            if (!$skills) {
                Write-Host "Please provide a 'skills' for the expert-level response." -ForegroundColor Red
                return
            }
            if (!$time) {
                Write-Host "Please provide a 'time' for the expert-level response." -ForegroundColor Red
                return
            }

            write-host "Prompt: Based on my goal: $goal, my skills: $skills, and time: $time, build a step-by-step plan I can follow to achieve it."
            gemini -p "Based on my goal: $goal, my skills: $skills, and time: $time, build a step-by-step plan I can follow to achieve it. Format the response in markdown with numbered steps, headers for phases, and checkboxes for tasks."
        }
        # Need to add a prompt for generating mermaid diagrams
        # In the docs folder create the optimal type of mermaid diagram that represents the structure of all of the things going on in the ContosoAds Support API
        default {
            Write-Host "Invalid type: $Type. Options are: email, prompt, summarizetext, summarizetopic, brainstorm, expert, askme, faketool, extract, plan" -ForegroundColor Red
            return
        }
    }
    
    # Set-Clipboard -Value $clipboardText
    Write-Host $clipboardText
}

# Decodes a base64 encoded string
function Base64Decode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base64String
    )
    
    try {
        # Remove any whitespace that might interfere with decoding
        $cleanBase64 = $Base64String.Trim()
        
        # Decode the base64 string
        $decodedBytes = [Convert]::FromBase64String($cleanBase64)
        $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        
        Write-Host "Decoded text: $decodedText" -ForegroundColor Green
        return $decodedText
    }
    catch {
        Write-Host "Error decoding base64 string: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function CleanEventLog, DumpEventLog, HostsFile, AiExpander, Base64Decode