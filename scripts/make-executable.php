<?php
/**
 * Cross-platform script to make shell scripts executable
 * This runs automatically after composer autoload dump
 */

// Skip on Windows
if (PHP_OS_FAMILY === 'Windows') {
    echo "ℹ️  Windows detected - scripts don't need chmod\n";
    exit(0);
}

// Find all shell scripts
$scriptsDir = __DIR__;
$shellScripts = glob($scriptsDir . '/*.sh');

if (empty($shellScripts)) {
    echo "ℹ️  No shell scripts found in scripts directory\n";
    exit(0);
}

$count = 0;
$errors = [];

foreach ($shellScripts as $script) {
    $scriptName = basename($script);
    
    if (chmod($script, 0755)) {
        $count++;
        echo "✅ Made {$scriptName} executable\n";
    } else {
        $errors[] = $scriptName;
        echo "⚠️  Could not make {$scriptName} executable\n";
    }
}

// Summary
if ($count > 0) {
    echo "🎉 Made {$count} shell scripts executable\n";
} else {
    echo "❌ Could not make any scripts executable\n";
}

if (!empty($errors)) {
    echo "⚠️  Failed to set permissions for: " . implode(', ', $errors) . "\n";
    echo "💡 You may need to run: chmod +x scripts/*.sh\n";
}
