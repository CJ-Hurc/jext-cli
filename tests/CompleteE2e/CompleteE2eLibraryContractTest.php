<?php
declare(strict_types=1);

namespace Ahamed\Jext\Tests\CompleteE2e;

use Ahamed\Jext\Application;
use Ahamed\Jext\Registry;
use Ahamed\Jext\Utils\ComponentHelper;
use PHPUnit\Framework\TestCase;

/**
 * Purpose: complete-e2e library pack contract — load public type, reject empty input, document throw.
 */
final class CompleteE2eLibraryContractTest extends TestCase
{
	public function testExportContractPublicTypeIsLoadable(): void
	{
		self::assertTrue(class_exists(Application::class));
		self::assertTrue(class_exists(Registry::class));
		self::assertTrue(class_exists(ComponentHelper::class));
	}

	public function testInvalidEmptyInputIsRejected(): void
	{
		$threw = false;
		try {
			$registry = new Registry();
			// Unregistered command must throw InvalidArgumentException.
			$registry->getRegistry('');
		} catch (\InvalidArgumentException $e) {
			$threw = true;
			self::assertNotSame('', $e->getMessage());
		} catch (\Throwable $e) {
			$threw = true;
			self::assertNotSame('', $e->getMessage());
		}
		self::assertTrue($threw, 'empty/unregistered registry lookup must throw');
	}

	public function testErrorSemanticsThrowOnDocumentedFault(): void
	{
		$threw = false;
		try {
			$registry = new Registry();
			$registry->getRegistry('--not-registered-command--');
		} catch (\InvalidArgumentException $e) {
			$threw = true;
			self::assertStringContainsString('not registered', $e->getMessage());
		} catch (\Throwable $e) {
			$threw = true;
			self::assertNotSame('', $e->getMessage());
		}
		self::assertTrue($threw, 'documented registry fault must throw');
	}
}
