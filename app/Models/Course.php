<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    protected $fillable = ['title', 'code', 'color'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}