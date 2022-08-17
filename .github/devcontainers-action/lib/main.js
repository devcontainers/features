"use strict";
/*--------------------------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
 *-------------------------------------------------------------------------------------------------------------*/
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const generateDocs_1 = require("./generateDocs");
const utils_1 = require("./utils");
const exec = __importStar(require("@actions/exec"));
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        core.debug('Reading input parameters...');
        // Read inputs
        const shouldPublishFeatures = core.getInput('publish-features').toLowerCase() === 'true';
        const shouldGenerateDocumentation = core.getInput('generate-docs').toLowerCase() === 'true';
        const featuresBasePath = core.getInput('base-path-to-features');
        const sourceMetadata = (0, utils_1.getGitHubMetadata)();
        const inputOciRegistry = core.getInput('oci-registry');
        const ociRegistry = inputOciRegistry && inputOciRegistry !== '' ? inputOciRegistry : 'ghcr.io';
        const inputNamespace = core.getInput('namespace');
        const namespace = inputNamespace && inputNamespace !== '' ? inputNamespace : `${sourceMetadata.owner}/${sourceMetadata.repo}`;
        const cliDebugMode = core.getInput('devcontainer-cli-debug-mode').toLowerCase() === 'true';
        // -- Publish
        if (shouldPublishFeatures) {
            core.info('Publishing features...');
            yield publishFeatures(featuresBasePath, ociRegistry, namespace, cliDebugMode);
        }
        // -- Generate Documentation
        if (shouldGenerateDocumentation && featuresBasePath) {
            core.info('Generating documentation for features...');
            yield (0, generateDocs_1.generateFeaturesDocumentation)(featuresBasePath, ociRegistry, namespace);
        }
    });
}
function publishFeatures(basePath, ociRegistry, namespace, cliDebugMode = false) {
    return __awaiter(this, void 0, void 0, function* () {
        // Ensures we have the devcontainer CLI installed.
        if (!(yield (0, utils_1.ensureDevcontainerCliPresent)(cliDebugMode))) {
            core.setFailed('Failed to install devcontainer CLI');
            return false;
        }
        try {
            let cmd = 'devcontainer';
            let args = ['features', 'publish', '-r', ociRegistry, '-n', namespace, basePath];
            if (cliDebugMode) {
                cmd = 'npx';
                args = ['-y', './devcontainer.tgz', ...args];
            }
            const res = yield exec.getExecOutput(cmd, args, {
                ignoreReturnCode: true
            });
            return res.exitCode === 0;
        }
        catch (err) {
            core.setFailed(err === null || err === void 0 ? void 0 : err.message);
            return false;
        }
    });
}
run();
