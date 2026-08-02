<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ChatController extends Controller
{
    public function send(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:2000',
        ]);

        $apiKey = config('services.groq.key');

        $response = Http::withToken($apiKey)->post(
            "https://api.groq.com/openai/v1/chat/completions",
            [
                'model' => 'openai/gpt-oss-20b',
                'messages' => [
                    ['role' => 'user', 'content' => $validated['message']],
                ],
            ]
        );

        if ($response->failed()) {
            return response()->json([
                'message' => 'Failed to get AI response',
                'debug_status' => $response->status(),
                'debug_body' => $response->json(),
            ], 500);
        }

        $data = $response->json();
        $reply = $data['choices'][0]['message']['content'] ?? 'No response generated.';

        return response()->json(['reply' => $reply]);
    }
}