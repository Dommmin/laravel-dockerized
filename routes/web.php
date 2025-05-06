<?php

use App\Http\Controllers\FileController;
use App\Mail\TestMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');
});

// Health check endpoint
Route::get('/up', function () {
    return response()->json(['status' => 'ok'], 200);
});

Route::get('/test-mail', function () {
    try {
        Mail::to('text@example.com')->queue(new TestMail());
    } catch (Exception $e) {
        return $e->getMessage();
    }

    return 'Mail sent';
});

Route::resource('/files', FileController::class)
    ->only(['index', 'store', 'destroy'])
    ->middleware('auth');

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
