<?php

namespace App\Http\Controllers;

use App\Models\File;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Inertia\Inertia;

class FileController extends Controller
{
    public function index()
    {
        return Inertia::render('Files/Index', [
            'files' => File::all(),
        ]);
    }

    public function store(Request $request)
    {
        if ($file = $request->file('file')) {
            $fileName = Str::uuid() . '.' . $file->getClientOriginalExtension();
            $path = Storage::disk('public')->putFileAs('files', $file, $fileName);
            $name = $file->getClientOriginalName();

            File::create([
                'name' => $name,
                'path' => $path,
            ]);
        } else {
            return to_route('files.index')->with('error', 'File upload failed.');
        }

        return to_route('files.index')->with('success', 'File uploaded successfully.');
    }

    public function destroy(Request $request, File $file)
    {
        $file->delete();

        return to_route('files.index')->with('success', 'File deleted successfully.');
    }
}
