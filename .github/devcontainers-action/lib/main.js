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
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        core.debug('Reading input parameters...');
        // Read inputs
        const shouldPublishFeatures = core.getInput('publish-features').toLowerCase() === 'true';
        const shouldPublishTemplates = core.getInput('publish-templates').toLowerCase() === 'true';
        const shouldGenerateDocumentation = core.getInput('generate-docs').toLowerCase() === 'true';
        // Experimental
        const shouldTagIndividualFeatures = core.getInput('tag-individual-features').toLowerCase() === 'true';
        const shouldPublishToNPM = core.getInput('publish-to-npm').toLowerCase() === 'true';
        const shouldPublishReleaseArtifacts = core.getInput('publish-release-artifacts').toLowerCase() === 'true';
        const shouldPublishToOCI = core.getInput('publish-to-oci').toLowerCase() === 'true';
        const opts = {
            shouldTagIndividualFeatures,
            shouldPublishToNPM,
            shouldPublishReleaseArtifacts,
            shouldPublishToOCI
        };
        const featuresBasePath = core.getInput('base-path-to-features');
        const templatesBasePath = core.getInput('base-path-to-templates');
        const ociRegistry = core.getInput('oci-registry');
        const namespace = core.getInput('features-namespace');
        let featuresMetadata = undefined;
        let templatesMetadata = undefined;
        // -- Package Release Artifacts
        if (shouldPublishFeatures) {
            core.info('Publishing features...');
            featuresMetadata = yield packageFeatures(featuresBasePath, opts);
        }
        if (shouldPublishTemplates) {
            core.info('Publishing template...');
            templatesMetadata = yield packageTemplates(templatesBasePath);
        }
        // -- Generate Documentation
        if (shouldGenerateDocumentation && featuresBasePath) {
            core.info('Generating documentation for features...');
            yield (0, generateDocs_1.generateFeaturesDocumentation)(featuresBasePath, ociRegistry, namespace);
        }
        if (shouldGenerateDocumentation && templatesBasePath) {
            core.info('Generating documentation for templates...');
            yield (0, generateDocs_1.generateTemplateDocumentation)(templatesBasePath);
        }
        // -- Programatically add feature/template metadata to collections file.
        core.info('Generating metadata file: devcontainer-collection.json');
        yield (0, utils_1.addCollectionsMetadataFile)(featuresMetadata, templatesMetadata, opts);
    });
}
function packageFeatures(basePath, opts) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all features in ${basePath}`);
            const metadata = yield (0, utils_1.getFeaturesAndPackage)(basePath, opts);
            core.info('Packaging features has finished.');
            return metadata;
        }
        catch (error) {
            if (error instanceof Error) {
                core.setFailed(error.message);
            }
        }
        return;
    });
}
function packageTemplates(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all templates in ${basePath}`);
            const metadata = yield (0, utils_1.getTemplatesAndPackage)(basePath);
            core.info('Packaging templates has finished.');
            return metadata;
        }
        catch (error) {
            if (error instanceof Error) {
                core.setFailed(error.message);
            }
        }
        return;
    });
}
run();
