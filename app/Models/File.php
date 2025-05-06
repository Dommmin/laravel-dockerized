<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'path',
    ];

    protected $appends = ['url'];

    public function getUrlAttribute(): string
    {
        return asset('storage/' . $this->path);
    }
}
